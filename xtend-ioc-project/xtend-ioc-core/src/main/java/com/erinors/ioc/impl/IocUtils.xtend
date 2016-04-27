/*
 * #%L
 * xtend-ioc-core
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */

package com.erinors.ioc.impl

import com.erinors.ioc.shared.api.Any
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.ComponentLifecycleManager
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.ModuleImporter
import com.erinors.ioc.shared.api.NotRequired
import com.erinors.ioc.shared.api.Qualifier
import com.erinors.ioc.shared.api.Scope
import com.erinors.ioc.shared.api.Singleton
import com.erinors.ioc.shared.impl.ModuleImplementor
import com.erinors.ioc.spi.ModuleProcessorExtension
import com.google.common.base.Optional
import com.google.common.base.Supplier
import com.google.common.collect.ImmutableList
import com.google.common.collect.ImmutableMap
import java.lang.reflect.Array
import java.util.Collection
import java.util.Comparator
import java.util.List
import java.util.Map
import java.util.ServiceLoader
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.AnnotationTarget
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Declaration
import org.eclipse.xtend.lib.macro.declaration.Element
import org.eclipse.xtend.lib.macro.declaration.EnumerationValueDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.GlobalTypeLookup
import org.eclipse.xtend.lib.macro.services.Problem.Severity
import org.eclipse.xtend.lib.macro.services.TypeReferenceProvider

import static extension com.erinors.ioc.impl.ProcessorUtils.*
import static extension com.erinors.ioc.shared.util.MapUtils.*

@FinalFieldsConstructor
class IocProcessingContext
{
	@Accessors
	val TransformationContext transformationContext

	val messages = <ProcessingMessage>newArrayList

	def Collection<? extends ProcessingMessage> getMessages()
	{
		return messages.immutableCopy
	}

	def void addMessage(ProcessingMessage message)
	{
		messages.add(message)
	}
}

class PriorityComparator<T extends HasPriority> implements Comparator<T>
{
	override compare(T o1, T o2)
	{
		return Integer.compare(o2.priority, o1.priority)
	}
}

class IocUtils
{
	def static String moduleImplementationClassName(Type moduleInterfaceType)
	'''«moduleInterfaceType.qualifiedName»Implementation'''

	def static TypeReference getProviderTypeReference(ComponentReference componentReference,
		extension TypeReferenceProvider context)
	{
		getProviderTypeReference(componentReference.providerType,
			componentReference.signature.componentTypeSignature.typeReference, context)
	}

	def static TypeReference getProviderTypeReference(ProviderType providerType, TypeReference typeReference,
		extension TypeReferenceProvider context)
	{
		if (providerType.byProvider)
			providerType.providerClassName.newTypeReference(typeReference)
		else
			typeReference
	}

	def static getComponentScopeAnnotation(AnnotationTarget annotationTarget, extension TransformationContext context)
	{
		val scopeAnnotations = annotationTarget.annotations.filter [
			annotationTypeDeclaration.hasAnnotation(Scope.findTypeGlobally)
		]

		if (scopeAnnotations.empty)
		{
			Singleton.newAnnotationReference.annotationTypeDeclaration
		}
		else if (scopeAnnotations.size == 1)
		{
			scopeAnnotations.head.annotationTypeDeclaration
		}
		else
		{
			throw new IocProcessingException(
				new ProcessingMessage(
					Severity.
						ERROR,
					annotationTarget,
					'''Multiple @Scope annotations found on «annotationTarget»: «scopeAnnotations.map[annotationTypeDeclaration.qualifiedName]»'''
				)
			)
		}
	}

	def static getLifecycleManagerClass(AnnotationTarget annotationTarget, extension TransformationContext context)
	{
		val scopeAnnotation = annotationTarget.getComponentScopeAnnotation(context)

		val scopeManager = scopeAnnotation.getAnnotation(Scope.findTypeGlobally).getClassValue("value").type

		if (scopeManager instanceof ClassDeclaration)
			if (ComponentLifecycleManager.newTypeReference.isAssignableFrom(scopeManager.newTypeReference))
				scopeManager
			else
				throw new IocProcessingException(
					new ProcessingMessage(
						Severity.
							ERROR,
						annotationTarget,
						'''Scope manager class «scopeManager.qualifiedName» specified on «scopeAnnotation» should implement «ComponentLifecycleManager.name».'''
					)
				)
		else
			throw new IocProcessingException(
				new ProcessingMessage(
					Severity.ERROR,
					annotationTarget,
					'''Scope manager specified on «scopeAnnotation» should be a class: «scopeManager.qualifiedName»'''
				)
			)
	}

	def static isInjected(AnnotationTarget annotationTarget, extension TransformationContext context)
	{
		annotationTarget.hasAnnotation(Inject.findTypeGlobally) || ("javax.inject.Inject".findTypeGlobally !== null &&
			annotationTarget.hasAnnotation("javax.inject.Inject".findTypeGlobally))
	}

	def static findInjectedConstructors(ClassDeclaration classDeclaration, extension TransformationContext context)
	{
		classDeclaration.declaredConstructors.filter[isInjected(context)]
	}

	def static findInjectedFields(ClassDeclaration classDeclaration, extension TransformationContext context)
	{
		classDeclaration.declaredFields.filter[isInjected(context)]
	}

	// TODO check if public
//	def static findDeclaredNoargsConstructor(ClassDeclaration classDeclaration, extension Tracability tracability)
//	{
//		val constructor = classDeclaration.declaredConstructors.filter[parameters.empty].head
//		if (constructor !== null && constructor.isThePrimaryGeneratedJavaElement)
//			constructor
//		else
//			null
//	}
	def static findQualifiers(AnnotationTarget annotationTarget, extension TransformationContext context)
	{
		annotationTarget.annotations.filter [
			annotationTypeDeclaration.hasAnnotation(Qualifier.findTypeGlobally)
		].map [
			buildQualifierModel(context)
		].toSet.immutableCopy
	}

	def static findComponentQualifiers(AnnotationTarget annotationTarget, extension TransformationContext context)
	{
		val qualifiers = findQualifiers(annotationTarget, context)

		if (qualifiers.empty)
			#{new QualifierModel(Default.name, ImmutableMap.of)}
		else
			qualifiers
	}

	def private static buildQualifierModel(AnnotationReference qualifierAnnotationReference,
		extension TransformationContext context)
	{
		new QualifierModel(qualifierAnnotationReference.annotationTypeDeclaration.qualifiedName,
			qualifierAnnotationReference.extractQualifierAttributes(context))
	}

	def static collectParameterizedQualifiers(AnnotationReference providerAnnotationReference)
	{
		val parameterizedQualifiers = providerAnnotationReference.getAnnotationArrayValue("parameterizedQualifiers").
			groupBy[getClassValue("qualifier")]

		val result = newLinkedList
		parameterizedQualifiers.forEach [ p1, p2 |
			result.add(new ParameterizedQualifierModel(p1.name, p2.map [
				getIntValue("parameterIndex") -> getStringValue("attributeName")
			].pairsToMap))
		]
		result
	}

	def private static Map<String, ? extends QualifierAttributeValue> extractQualifierAttributes(
		AnnotationReference annotationReference, extension TransformationContext context)
	{
		val annotationAttributes = annotationReference.annotationTypeDeclaration.declaredAnnotationTypeElements

		if (annotationAttributes.exists [ attribute |
			val attributeValue = annotationReference.getValue(attribute.simpleName)
			attributeValue.convertQualifierAttributeValue(context) === null
		])
		{
			// Check if the annotation reference has compilation error.
			// In this case attribute.simpleName is valid but getValue() returns null
			throw new CancelOperationException
		}

		annotationAttributes.map [ attribute |
			val attributeName = attribute.simpleName
			val attributeValue = annotationReference.getValue(attributeName)
			val convertedAttributeValue = attributeValue.convertQualifierAttributeValue(context)
			attributeName -> convertedAttributeValue
		].pairsToMap.immutableCopy
	}

	def private static QualifierAttributeValue convertQualifierAttributeValue(Object attributeValue,
		extension TransformationContext context)
	{
		switch (attributeValue)
		{
			case null:
				null
			AnnotationReference:
				attributeValue.buildQualifierModel(context)
			EnumerationValueDeclaration:
				new QualifierAttributeEnumValue(attributeValue.declaringType.qualifiedName, attributeValue.simpleName)
			TypeReference:
				new QualifierAttributeClassValue(attributeValue.type.qualifiedName)
			case attributeValue.class.array:
				convertQualifierAttributeArrayValue(attributeValue, context)
			default:
				new QualifierAttributePrimitiveValue(attributeValue)
		}
	}

	def private static QualifierAttributeArrayValue convertQualifierAttributeArrayValue(Object array,
		extension TransformationContext context)
	{
		val listBuilder = ImmutableList.builder

		val length = Array.getLength(array)
		for (var i = 0; i < length; i++)
		{
			val element = Array.get(array, i)

			if (element instanceof Object[])
			{
				element.convertQualifierAttributeArrayValue(context)
			}
			else
			{
				element.convertQualifierAttributeValue(context)
			}
		}

		return new QualifierAttributeArrayValue(listBuilder.build)
	}

	def static Iterable<ProcessingMessage> validateComponentType(Type componentType,
		InterfaceDeclaration moduleInterfaceDeclaration, extension GlobalTypeLookup context)
	{
		if (componentType instanceof ClassDeclaration)
		{
			if (!componentType.typeParameters.empty)
			{
				#[
					new ProcessingMessage(
						Severity.ERROR,
						componentType,
						'''Component class should be non-generic: «componentType.qualifiedName» [E005]'''
					)
				]
			}
			else if (!componentType.isComponentClass)
			{
				#[
					new ProcessingMessage(
						Severity.ERROR,
						componentType,
						'''Component class must be annotated with @Component.'''
					)
				]
			}
			else
			{
				#[]
			}
		}
		else
		{
			#[
				new ProcessingMessage(Severity.ERROR,
					componentType, '''Only classes are supported as components: «componentType.qualifiedName»''')]
		}
	}

	private static def ProviderType providerType(TypeReference typeReference)
	{
		switch (typeReference.type.qualifiedName)
		{
			case Supplier.name: ProviderType.GUAVA_SUPPLIER
			case Optional.name: ProviderType.GUAVA_OPTIONAL
			default: ProviderType.DIRECT
		}
	}

	def static GeneratedComponentReference createGeneratedComponentReference(TypeReference targetTypeReference,
		Element compilationProblemTarget, extension TransformationContext context)
	{
		new GeneratedComponentReference(targetTypeReference, compilationProblemTarget)
	}

	// TODO rename
	// TODO rename params
	def static <T extends Declaration> DeclaredComponentReference<T> createDeclaredComponentReference(
		T dependencyReferenceDeclaration, TypeReference targetTypeReference, extension TransformationContext context)
	{
		val compilationProblemTarget = dependencyReferenceDeclaration

		val isIterable = Iterable.newTypeReference.isAssignableFrom(targetTypeReference)

		if (isIterable)
		{
			val invalid = switch (targetTypeReference.type)
			{
				case Iterable.findTypeGlobally:
					false
				case Collection.findTypeGlobally:
					false
				case List.findTypeGlobally:
					false
				default:
					true
			}

			if (invalid)
			{
				throw new IocProcessingException(
					new ProcessingMessage(
						Severity.
							ERROR,
						compilationProblemTarget,
						'''Collections of dependencies can be referenced only by Iterable, Collection and List types, «targetTypeReference.toDisplayName» is not supported.'''
					)
				)
			}

			if (targetTypeReference.actualTypeArguments.empty)
			{
				throw new IocProcessingException(
					new ProcessingMessage(
						Severity.
							ERROR,
						compilationProblemTarget,
						'''Raw collections of dependencies are not supported, add a type argument to «dependencyReferenceDeclaration.asString».'''
					)
				)
			}
		}

		if (Map.newTypeReference.isAssignableFrom(targetTypeReference))
		{
			throw new IocProcessingException(
				new ProcessingMessage(
					Severity.ERROR,
					compilationProblemTarget,
					'''Maps of dependencies are not supported: «dependencyReferenceDeclaration.asString»'''
				)
			)
		}

		val cardinalityType = if (isIterable) CardinalityType.MULTIPLE else CardinalityType.SINGLE

		val providerType = if (isIterable)
				targetTypeReference.actualTypeArguments.get(0).upperBound.providerType
			else
				targetTypeReference.providerType

		if (cardinalityType == CardinalityType.MULTIPLE && providerType == ProviderType.GUAVA_OPTIONAL)
		{
			throw new IocProcessingException(
				new ProcessingMessage(
					Severity.
						ERROR,
					compilationProblemTarget,
					'''Collection of Optionals is not supported, use Supplier instead of Optional at «dependencyReferenceDeclaration.asString».'''
				)
			)
		}

		val byProvider = providerType.byProvider

		if (byProvider)
		{
			val invalid = if (isIterable)
					targetTypeReference.actualTypeArguments.get(0).actualTypeArguments.empty
				else
					targetTypeReference.actualTypeArguments.empty

			if (invalid)
			{
				throw new IocProcessingException(
					new ProcessingMessage(
						Severity.
							ERROR,
						compilationProblemTarget,
						'''Raw Suppliers are not supported, add a type argument to «dependencyReferenceDeclaration.asString».'''
					)
				)
			}
		}

		val typeReference = if (isIterable)
			{
				if (byProvider)
					targetTypeReference.actualTypeArguments.get(0).actualTypeArguments.get(0).upperBound
				else
					targetTypeReference.actualTypeArguments.get(0).upperBound
			}
			else
			{
				if (byProvider)
					targetTypeReference.actualTypeArguments.get(0).upperBound
				else
					targetTypeReference
			}

		// TODO warning when @NotRequired on collection, it is redundant
		// TODO warning when @NotRequired on Optional, it is redundant
		val optional = cardinalityType == CardinalityType.MULTIPLE ||
			dependencyReferenceDeclaration.hasAnnotation(NotRequired.findTypeGlobally) || providerType.implicitOptional

		val qualifiers = findQualifiers(dependencyReferenceDeclaration, context)

		val any = dependencyReferenceDeclaration.hasAnnotation(Any)

		new DeclaredComponentReference(new ComponentReferenceSignature(
			new ComponentTypeSignature(typeReference.wrapperIfPrimitive, qualifiers),
			cardinalityType
		), providerType, optional, any, dependencyReferenceDeclaration, targetTypeReference)
	}

	@Data
	package static class ParameterizedQualifierReference
	{
		ParameterizedQualifierModel parameterizedQualifier

		QualifierModel referencingQualifier
	}

	def static hasInterceptorAnnotation(MethodDeclaration methodDeclaration)
	{
		methodDeclaration.annotations.exists[isInterceptorAnnotation]
	}

	def static isInterceptorAnnotation(AnnotationReference annotationReference)
	{
		annotationReference.getInterceptorMetaAnnotation !== null
	}

	def private static getInterceptorMetaAnnotation(AnnotationReference annotationReference)
	{
		annotationReference.annotationTypeDeclaration.annotations.filter [
			annotationTypeDeclaration.qualifiedName == Interceptor.name
		].head
	}

	def static getInterceptorInvocationHandler(AnnotationReference annotationReference)
	{
		val result = annotationReference.interceptorMetaAnnotation.getClassValue("value")

		if (result === null)
		{
			throw new CancelOperationException
		}

		result
	}

	def static isComponentClass(TypeReference typeReference)
	{
		isComponentClass(typeReference.type)
	}

	def static isComponentClass(Type type)
	{
		if (type instanceof ClassDeclaration)
			type.hasAnnotation(Component.name)
		else
			false
	}

	static def handleExceptions(Exception e, extension TransformationContext context, Declaration defaultDeclaration)
	{
		switch (e)
		{
			IocProcessingException:
			{
				processMessages(e.messages, defaultDeclaration, context)
			}
			CancelOperationException:
			{
				// Ignore exception
			}
			default:
				throw new IllegalStateException('''Internal xtend-ioc error: «e.message»''', e)
		}
	}

	def static processMessages(Iterable<? extends ProcessingMessage> messages, Declaration defaultDeclaration,
		extension TransformationContext context)
	{
		messages.forEach [
			try
			{
				addError(if (element !== null) element else defaultDeclaration, message)
			}
			catch (Exception e1)
			{
				addError(defaultDeclaration, '''Error at «element.toDisplayName». «message»''')
			}
		]
	}

	def static importedModules(InterfaceDeclaration moduleInterface)
	{
		val moduleAnnotation = moduleInterface.getAnnotation(Module)
		val moduleImporters = moduleAnnotation.getClassArrayValue("moduleImporters")

		moduleImporters.map [ moduleImporter |
			(moduleImporter.type as AnnotationTarget).getAnnotation(ModuleImporter).getStringValue("moduleClassName")
		]
	}

	def static inheritedModules(InterfaceDeclaration moduleInterface)
	{
		moduleInterface.extendedInterfaces.filter[type.qualifiedName != ModuleImplementor.name]
	}

	def static findModuleProcessorExtensions()
	{
		ServiceLoader.load(ModuleProcessorExtension, ModuleProcessorImplementation.classLoader);
	}

	def static String modulePeerClassName(TypeReference moduleType)
	'''«modulePeerClassName(moduleType.type.qualifiedName)»'''

	def static String modulePeerClassName(String moduleQualifiedName)
	'''«moduleQualifiedName».Peer'''

	def static isAssignableFrom(Set<? extends QualifierModel> qualifiers, Set<? extends QualifierModel> otherQualifiers)
	{
		otherQualifiers.containsAll(qualifiers)
	}
}

class OrderComparator<T extends HasOrder> implements Comparator<T>
{
	val public static INSTANCE = new OrderComparator

	override compare(T o1, T o2)
	{
		return Integer.compare(o1.order, o2.order)
	}
}
