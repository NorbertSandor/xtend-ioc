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

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Eager
import com.erinors.ioc.shared.api.Priority
import com.erinors.ioc.shared.api.SupportsPredestroyCallbacks
import javax.annotation.PostConstruct
import javax.annotation.PreDestroy
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.ConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.Problem.Severity

import static extension com.erinors.ioc.impl.IocUtils.*
import static extension com.erinors.ioc.impl.ProcessorUtils.*

@FinalFieldsConstructor
class ComponentClassModelBuilder
{
	val extension TransformationContext context

	def private findConstructorComponentReferences(TypeReference componentClassTypeReference)
	{
		val componentConstructor = componentClassTypeReference.findResolvedComponentConstructor
		if (componentConstructor !== null)
		{
			componentConstructor.resolvedParameters.map [ resolvedParameter |
				createDependencyReference(resolvedParameter.declaration, resolvedParameter.resolvedType, context)
			].toList
		}
		else
			#[]
	}

	def private findFieldComponentReferences(TypeReference componentClassTypeReference)
	{
		val injectedFieldsSignatureMethod = componentClassTypeReference.declaredResolvedMethods.filter [
			declaration.hasAnnotation(InjectedFieldsSignatureMethod.findTypeGlobally)
		].head

		if (injectedFieldsSignatureMethod !== null)
		{
			val injectedFields = (componentClassTypeReference.type as ClassDeclaration).findInjectedFields(context)
			injectedFieldsSignatureMethod.resolvedParameters.map [ resolvedParameter |
				val fieldDeclaration = injectedFields.findFirst [
					simpleName == resolvedParameter.declaration.simpleName
				]
				createDependencyReference(fieldDeclaration, resolvedParameter.resolvedType, context)
			].toList
		}
		else
		{
			throw new IocProcessingException(new ProcessingMessage(
				Severity.ERROR,
				componentClassTypeReference,
				'''Component class must be declared before any module that references it.'''
			))
		}
	}

	def private ComponentSuperclassModel buildSuperclassModel(TypeReference componentClassTypeReference)
	{
		val componentClassDeclaration = componentClassTypeReference.type

		if (componentClassDeclaration instanceof ClassDeclaration)
		{
			val componentAnnotation = componentClassDeclaration.findAnnotation(Component.findTypeGlobally)
			if (componentAnnotation == null)
			{
				null
			}
			else
			{
				new ComponentSuperclassModel(
					componentClassTypeReference,
					if (componentClassTypeReference.hasSuperclass)
						componentClassTypeReference.superclass.buildSuperclassModel
					else
						null,
					componentClassTypeReference.findFieldComponentReferences,
					componentClassTypeReference.findConstructorComponentReferences
				)
			}
		}
		else
		{
			throw new IocProcessingException(
				new ProcessingMessage(
					Severity.ERROR,
					componentClassTypeReference,
					'''Component class expected but «componentClassDeclaration.qualifiedName» is not a class.'''
				)
			)
		}
	}

	def private findResolvedComponentConstructor(TypeReference componentClassTypeReference)
	{
		componentClassTypeReference.declaredResolvedConstructors.findFirst [
			declaration.hasAnnotation(DeclaredComponentConstructor.findTypeGlobally)
		]
	}

	def private findComponentConstructor(ClassDeclaration componentClassDeclaration)
	{
		if (componentClassDeclaration.declaredConstructors.empty ||
			componentClassDeclaration.findDefaultConstructor(context) !== null)
		{
			null
		}
		else
		{
			val injectedConstructors = componentClassDeclaration.findInjectedConstructors(context)

			if (injectedConstructors.empty)
			{
				throw new IocProcessingException(
					new ProcessingMessage(
						Severity.
							ERROR
						,
						componentClassDeclaration,
						'''Component should have an @Inject-ed constructor (because it has one or more constructors declared).'''
					))
			}
			else if (injectedConstructors.size > 1)
			{
				throw new IocProcessingException(new ProcessingMessage(
					Severity.ERROR,
					componentClassDeclaration,
					'''Component class may have at most one @Inject-ed constructor.'''
				))
			}
			else
			{
				injectedConstructors.head
			}
		}
	}

	def private findFieldComponentReferences(ClassDeclaration componentClassDeclaration)
	{
		componentClassDeclaration.findInjectedFields(context).map [
			createDependencyReference(it, type, context)
		].toList.immutableCopy
	}

	def private findConstructorComponentReferences(ConstructorDeclaration declaredComponentConstructor)
	{
		declaredComponentConstructor.parameters.map [
			createDependencyReference(it, type, context)
		]
	}

	def private findConstructorComponentReferences(ClassDeclaration componentClassDeclaration)
	{
		val declaredComponentConstructor = componentClassDeclaration.findComponentConstructor

		if (declaredComponentConstructor !== null)
			declaredComponentConstructor.findConstructorComponentReferences.toList.immutableCopy
		else
			#[]
	}

	def ComponentClassModel build(TypeReference componentClassTypeReference)
	{
		val componentClassDeclaration = componentClassTypeReference.type as ClassDeclaration
		return new ComponentClassModel(
			new ComponentTypeSignature(getComponentClassType(componentClassDeclaration),
				componentClassDeclaration.findQualifiers(context)),
			componentClassDeclaration.getLifecycleManagerClass(context),
			componentClassDeclaration.getComponentClassPriority,
			componentClassDeclaration,
			if (componentClassTypeReference.hasSuperclass)
				buildSuperclassModel(componentClassTypeReference.superclass)
			else
				null,
			componentClassTypeReference.findResolvedComponentConstructor?.declaration,
			componentClassTypeReference.findFieldComponentReferences,
			componentClassTypeReference.findConstructorComponentReferences,
			componentClassDeclaration.findPostConstructMethods,
			findPreDestroyMethods(componentClassDeclaration),
			componentClassDeclaration.hasAnnotation(Eager.findTypeGlobally)
		)
	}

	def ComponentClassModel build(ClassDeclaration componentClassDeclaration)
	{
		val lifecycleManagerClass = componentClassDeclaration.getLifecycleManagerClass(context)

		val predestroyMethods = findPreDestroyMethods(componentClassDeclaration)
		if (!predestroyMethods.empty &&
			!lifecycleManagerClass.hasAnnotation(SupportsPredestroyCallbacks.findTypeGlobally))
		{
			throw new IocProcessingException(
			predestroyMethods.map [
				new ProcessingMessage(
					Severity.
						ERROR
					,
					it,
					'''Scope @«componentClassDeclaration.getComponentScopeAnnotation(context).simpleName» does not support @PreDestroy methods.'''
				)
			])
		}

		return new ComponentClassModel(
			new ComponentTypeSignature(getComponentClassType(componentClassDeclaration),
				componentClassDeclaration.findQualifiers(context)),
			lifecycleManagerClass,
			componentClassDeclaration.getComponentClassPriority,
			componentClassDeclaration,
			if (componentClassDeclaration.hasSuperclass)
				buildSuperclassModel(componentClassDeclaration.extendedClass)
			else
				null,
			componentClassDeclaration.findComponentConstructor,
			componentClassDeclaration.findFieldComponentReferences,
			componentClassDeclaration.findConstructorComponentReferences,
			componentClassDeclaration.findPostConstructMethods,
			predestroyMethods,
			componentClassDeclaration.hasAnnotation(Eager.findTypeGlobally)
		)
	}

	def getComponentClassType(ClassDeclaration componentClassDeclaration)
	{
		val componentAnnotation = componentClassDeclaration.findAnnotation(Component.findTypeGlobally)
		val type = if (componentAnnotation == null || componentAnnotation.getClassValue("type") == object)
				componentClassDeclaration.newTypeReference
			else
				componentAnnotation.getClassValue("type")
		type
	}

	def getComponentClassPriority(ClassDeclaration componentClassDeclaration)
	{
		val priorityAnnotation = componentClassDeclaration.findAnnotation(Priority.findTypeGlobally)
		return if (priorityAnnotation != null) priorityAnnotation.getIntValue("value") else 0
	}

	def private findPostConstructMethods(ClassDeclaration componentClassDeclaration)
	{
		componentClassDeclaration.declaredMethods.filter[hasAnnotation(PostConstruct.findTypeGlobally)].toList
	}

	def private findPreDestroyMethods(ClassDeclaration componentClassDeclaration)
	{
		componentClassDeclaration.declaredMethods.filter [
			hasAnnotation(PreDestroy.findTypeGlobally)
		].toList
	}

	// TODO nincsenek jó helyen
	private def hasSuperclass(ClassDeclaration classDeclaration)
	{
		classDeclaration.extendedClass !== null && classDeclaration.extendedClass != object
	}
}
// TODO mi van, ha a komponens és a superclass-a is bele van rakva a modulba
