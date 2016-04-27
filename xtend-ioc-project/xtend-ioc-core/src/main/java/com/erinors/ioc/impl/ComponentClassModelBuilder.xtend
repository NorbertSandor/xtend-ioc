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
import com.erinors.ioc.shared.api.Order
import com.erinors.ioc.shared.api.Priority
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.api.SupportsPredestroyCallbacks
import java.util.List
import javax.annotation.PostConstruct
import javax.annotation.PreDestroy
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.Problem.Severity

import static extension com.erinors.ioc.impl.IocUtils.*
import static extension com.erinors.ioc.impl.ProcessorUtils.*
import com.erinors.ioc.shared.api.EventObserver

@FinalFieldsConstructor
class ComponentClassModelBuilder
{
	val extension TransformationContext context

	def private findInterceptedMethods(TypeReference componentClassTypeReference)
	{
		// TODO skip provider methods
		componentClassTypeReference.declaredResolvedMethods.filter [
			!declaration.annotations.filter[isInterceptorAnnotation].empty
		].map [ resolvedMethod |
			resolvedMethod.declaration -> resolvedMethod.declaration.annotations.filter[isInterceptorAnnotation]
		]
	}

	def private findInterceptedMethods(ClassDeclaration componentClassDeclaration)
	{
		// TODO skip provider methods
		componentClassDeclaration.declaredMethods.filter [
			!annotations.filter[isInterceptorAnnotation].empty
		].map [ declaredMethod |
			declaredMethod -> declaredMethod.annotations.filter[isInterceptorAnnotation]
		]
	}

	def List<? extends EventObserverModel> findEventObservers(TypeReference componentClassTypeReference, TransformationContext context)
	{
		// TODO skip provider methods
		componentClassTypeReference.declaredResolvedMethods.filter [
			declaration.hasAnnotation(EventObserver)
		].map [ resolvedMethod |
			buildEventObserverModel(resolvedMethod.declaration, context)
		].toList.immutableCopy
	}

	def List<? extends EventObserverModel> findEventObservers(ClassDeclaration componentClassDeclaration, TransformationContext context)
	{
		// TODO skip provider methods
		componentClassDeclaration.declaredMethods.filter [
			hasAnnotation(EventObserver)
		].map [ declaredMethod |
			buildEventObserverModel(declaredMethod, context)
		].toList.immutableCopy
	}

	def buildEventObserverModel(MethodDeclaration methodDeclaration, TransformationContext context)
	{
		EventObserverModel.build[
			observerMethod = methodDeclaration
			eventType = if (methodDeclaration.parameters.empty) methodDeclaration.findAnnotation(EventObserver.findTypeGlobally).getClassValue("eventType") else methodDeclaration.parameters.get(0).type
			ignoreSubtypes = methodDeclaration.findAnnotation(EventObserver.findTypeGlobally).getBooleanValue("rejectSubtypes")
			qualifiers = findQualifiers(methodDeclaration, context) // TODO support qualifiers on parameter
		]
	}

	def private findGeneratedComponentReferences(TypeReference componentClassTypeReference)
	{
		componentClassTypeReference.findInterceptedMethods.map [
			val methodDeclaration = key
			val interceptorAnnotations = value

			interceptorAnnotations.map [ interceptorAnnotation |
				val handlerTypeReference = interceptorAnnotation.interceptorInvocationHandler
				createGeneratedComponentReference(handlerTypeReference, methodDeclaration, context)
			]
		].flatten.toSet.toList
	}

	def private findConstructorComponentReferences(TypeReference componentClassTypeReference)
	{
		val componentConstructor = componentClassTypeReference.findResolvedComponentConstructor
		if (componentConstructor !== null)
		{
			componentConstructor.resolvedParameters.map [ resolvedParameter |
				createDeclaredComponentReference(resolvedParameter.declaration, resolvedParameter.resolvedType, context)
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
			injectedFieldsSignatureMethod.resolvedParameters.indexed.map [ pair |
				val index = pair.key
				val resolvedParameter = pair.value

				// TODO another alternative is to generate one method for each required signature (the old solution used parameter lookup by name but it does not work because parameter names are not preserved in the class files)
				val fieldDeclaration = injectedFields.get(index)

				createDeclaredComponentReference(fieldDeclaration, resolvedParameter.resolvedType, context)
			].toList
		}
		else
		{
			throw new CancelOperationException
		// FIXME incorrect if the component is declared in the same file but after the module
//			throw new IocProcessingException(new ProcessingMessage(
//				Severity.ERROR,
//				componentClassTypeReference,
//				'''Component class is not transformed yet. Declare the component class before the module and/or fix the errors on the component class.'''
//			))
		}
	}

	def private ComponentSuperclassModel buildSuperclassModel(TypeReference componentClassTypeReference)
	{
		val componentClassDeclaration = componentClassTypeReference.type

		if (componentClassDeclaration instanceof ClassDeclaration)
		{
			if (componentClassDeclaration.isComponentClass)
			{
				new ComponentSuperclassModel(
					componentClassTypeReference,
					if (componentClassTypeReference.hasSuperclass)
						componentClassTypeReference.superclass.buildSuperclassModel
					else
						null,
					componentClassTypeReference.findFieldComponentReferences,
					componentClassTypeReference.findConstructorComponentReferences,
					componentClassTypeReference.findGeneratedComponentReferences,
					#[] // FIXME
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
							ERROR,
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
			createDeclaredComponentReference(it, type, context)
		].toList.immutableCopy
	}

	def private findGeneratedComponentReferences(ClassDeclaration componentClassDeclaration)
	{
		// TODO skip provider methods
		componentClassDeclaration.findInterceptedMethods.map [
			val methodDeclaration = key
			val interceptorAnnotations = value

			interceptorAnnotations.map [ interceptorAnnotation |
				val handlerTypeReference = interceptorAnnotation.interceptorInvocationHandler
				createGeneratedComponentReference(handlerTypeReference, methodDeclaration, context)
			]
		].flatten.toSet.toList
	}

	def private findConstructorComponentReferences(ClassDeclaration componentClassDeclaration)
	{
		val declaredComponentConstructor = componentClassDeclaration.findComponentConstructor

		if (declaredComponentConstructor !== null)
			declaredComponentConstructor.parameters.map [
				createDeclaredComponentReference(it, type, context)
			].toList.immutableCopy
		else
			#[]
	}

	def ComponentClassModel build(TypeReference componentClassTypeReference)
	{
		val componentClassDeclaration = componentClassTypeReference.type as ClassDeclaration
		return new ComponentClassModel(
			new ComponentTypeSignature(getComponentClassType(componentClassDeclaration),
				componentClassDeclaration.findComponentQualifiers(context)),
			componentClassDeclaration.getLifecycleManagerClass(context),
			componentClassDeclaration.getComponentClassPriority,
			componentClassDeclaration.getComponentClassOrder,
			componentClassDeclaration,
			if (componentClassTypeReference.hasSuperclass)
				buildSuperclassModel(componentClassTypeReference.superclass)
			else
				null,
			componentClassTypeReference.findResolvedComponentConstructor?.declaration,
			componentClassTypeReference.findFieldComponentReferences.immutableCopy,
			componentClassTypeReference.findConstructorComponentReferences.immutableCopy,
			componentClassTypeReference.findGeneratedComponentReferences.immutableCopy,
			componentClassDeclaration.findPostConstructMethods.immutableCopy,
			findPreDestroyMethods(componentClassDeclaration).immutableCopy,
			componentClassDeclaration.hasAnnotation(Eager.findTypeGlobally),
			componentClassTypeReference.findInterceptedMethods.map [
				createInterceptedMethod(key, value)
			].toList.immutableCopy,
			componentClassTypeReference.findEventObservers(context)
		)
	}

	def private createInterceptedMethod(MethodDeclaration methodDeclaration,
		Iterable<? extends AnnotationReference> interceptorAnnotationReferences)
	{
		new InterceptedMethod(methodDeclaration, interceptorAnnotationReferences.map [ interceptorAnnotationReference |
			val interceptorDefinitionModel = try
			{
				new InterceptorDefinitionModelBuilder(context).build(
					interceptorAnnotationReference.annotationTypeDeclaration)
			}
			catch (IocProcessingException e)
			{
				throw new CancelOperationException
			}

			val interceptorArguments = interceptorDefinitionModel.parameters.map [ parameter |
				val parameterType = parameter.type
				switch (parameterType)
				{
					BasicInterceptorParameterType:
						new BasicInterceptorArgument(parameterType,
							interceptorAnnotationReference.getValue(parameter.name))
					MethodReferenceInterceptorParameterType:
					{
						val methodName = interceptorAnnotationReference.getStringValue(parameter.name)

						val matchingMethods = methodDeclaration.declaringType.declaredMethods.filter [
							simpleName == methodName
						]
						if (matchingMethods.empty)
						{
							throw new IocProcessingException(new ProcessingMessage(
								Severity.ERROR,
								methodDeclaration,
								'''Referenced method not found: «methodName»''' // TODO more info
							))
						}

						val matchingMethod = matchingMethods.filter [
							// TODO why does not work without toList?
							parameters.map[type].toList == parameterType.parameterTypes.toList
						].head
						if (matchingMethod === null)
						{
							throw new IocProcessingException(
								new ProcessingMessage(
									Severity.
										ERROR,
									methodDeclaration,
									'''
										Method parameter type mismatch, expected: «parameterType.parameterTypes.map[name]»
										See the documentation of @«interceptorDefinitionModel.interceptorAnnotation.simpleName».«parameter.name» for more details.
									''' // TODO more info
								))
						}

						if (matchingMethod.returnType.inferred)
						{
							throw new IocProcessingException(new ProcessingMessage(
								Severity.ERROR,
								methodDeclaration,
								'''
									Inferred return type is not supported on methods referenced by interceptor annotations.
								''' // TODO more info
							))
						}

						if (!matchingMethod.returnType.isAssignableFrom(parameterType.returnType))
						{
							throw new IocProcessingException(
								new ProcessingMessage(
									Severity.
										ERROR,
									methodDeclaration,
									'''
										Method return type mismatch, expected: «parameterType.returnType.name»
										See the documentation of @«interceptorDefinitionModel.interceptorAnnotation.simpleName».«parameter.name» for more details.
									''' // TODO more info
								))
						}

						new MethodReferenceInterceptorArgument(parameterType, methodName)
					}
				}
			]

			new InterceptorInvocationModel(
				interceptorDefinitionModel,
				createGeneratedComponentReference(interceptorAnnotationReference.interceptorInvocationHandler,
					methodDeclaration, context),
				interceptorArguments
			)
		].toList)
	}

	def ComponentClassModel build(ClassDeclaration componentClassDeclaration)
	{
		val lifecycleManagerClass = componentClassDeclaration.getLifecycleManagerClass(context)

		componentClassDeclaration.declaredMethods.filter [
			hasAnnotation(Provider.findTypeGlobally)
		].forEach [
			if (returnType.inferred)
			{
				// TODO ezt a componentprocessor-nak kellene vizsgálni
				throw new IocProcessingException(
					new ProcessingMessage(
						Severity.
							ERROR,
						it,
						'''Provider method must have an explicit return type, type inference is not supported: «it.asString»'''
					))
			}
		]

		val predestroyMethods = findPreDestroyMethods(componentClassDeclaration)
		if (!predestroyMethods.empty &&
			!lifecycleManagerClass.hasAnnotation(SupportsPredestroyCallbacks.findTypeGlobally))
		{
			throw new IocProcessingException(
			predestroyMethods.map [
				new ProcessingMessage(
					Severity.
						ERROR,
					it,
					'''Scope @«componentClassDeclaration.getComponentScopeAnnotation(context).simpleName» does not support @PreDestroy methods.'''
				)
			])
		}

		return new ComponentClassModel(
			new ComponentTypeSignature(getComponentClassType(componentClassDeclaration),
				componentClassDeclaration.findComponentQualifiers(context)),
			lifecycleManagerClass,
			componentClassDeclaration.getComponentClassPriority,
			componentClassDeclaration.getComponentClassOrder,
			componentClassDeclaration,
			if (componentClassDeclaration.hasSuperclass)
				buildSuperclassModel(componentClassDeclaration.extendedClass)
			else
				null,
			componentClassDeclaration.findComponentConstructor,
			componentClassDeclaration.findFieldComponentReferences.immutableCopy,
			componentClassDeclaration.findConstructorComponentReferences.immutableCopy,
			componentClassDeclaration.findGeneratedComponentReferences.immutableCopy,
			componentClassDeclaration.findPostConstructMethods.immutableCopy,
			predestroyMethods.immutableCopy,
			componentClassDeclaration.hasAnnotation(Eager.findTypeGlobally),
			componentClassDeclaration.findInterceptedMethods.map [
				createInterceptedMethod(key, value)
			].toList.immutableCopy,
			componentClassDeclaration.findEventObservers(context)
		)
	}

	def private getComponentClassType(ClassDeclaration componentClassDeclaration)
	{
		val componentAnnotation = componentClassDeclaration.findAnnotation(Component.findTypeGlobally)
		(if (componentAnnotation.getClassValue("type") == object)
			componentClassDeclaration.newTypeReference
		else
			componentAnnotation.getClassValue("type")).wrapperIfPrimitive
	}

	def private getComponentClassPriority(ClassDeclaration componentClassDeclaration)
	{
		val priorityAnnotation = componentClassDeclaration.findAnnotation(Priority.findTypeGlobally)
		return if (priorityAnnotation !== null) priorityAnnotation.getIntValue("value") else 0
	}

	def private getComponentClassOrder(ClassDeclaration componentClassDeclaration)
	{
		val orderAnnotation = componentClassDeclaration.findAnnotation(Order.findTypeGlobally)
		return if (orderAnnotation !== null) orderAnnotation.getIntValue("value") else 0
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
}
// TODO mi van, ha a komponens és a superclass-a is bele van rakva a modulba
