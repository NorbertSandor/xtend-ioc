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
import com.erinors.ioc.shared.api.EventObserver
import com.erinors.ioc.shared.impl.ComponentReferenceSupplier
import com.erinors.ioc.shared.impl.EventMatcher
import com.erinors.ioc.shared.impl.ModuleImplementor
import com.erinors.ioc.shared.impl.ModuleInstance
import com.google.common.base.Function
import com.google.common.base.Optional
import com.google.common.collect.ImmutableList
import com.google.common.collect.Lists
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1

import static com.erinors.ioc.impl.InterceptorUtils.*
import static com.erinors.ioc.impl.IocUtils.*

import static extension com.erinors.ioc.impl.ProcessorUtils.*

class ComponentProcessor extends AbstractSafeClassProcessor
{
	new()
	{
		super(new ComponentProcessorImplementation, Component, "E002")
	}
}

@Target(METHOD)
annotation InjectedFieldsSignatureMethod
{
}

@Target(CONSTRUCTOR)
annotation GeneratedComponentConstructor
{
}

@Target(CONSTRUCTOR)
annotation DeclaredComponentConstructor
{
}

class ComponentProcessorImplementation extends AbstractClassProcessor
{
	val private static MODULE_IMPLEMENTOR_FIELD_NAME = "moduleImplementor"

	override doTransform(MutableClassDeclaration componentClassDeclaration, extension TransformationContext context)
	{
		try
		{
			val componentModel = new ComponentClassModelBuilder(context).build(componentClassDeclaration)

			(componentModel.componentConstructor as MutableConstructorDeclaration)?.addAnnotation(
				DeclaredComponentConstructor.newAnnotationReference)

			componentClassDeclaration.addField(MODULE_IMPLEMENTOR_FIELD_NAME, [
				type = ModuleImplementor.newTypeReference
				visibility = Visibility.PRIVATE
			])

			componentClassDeclaration.addMethod(componentClassDeclaration.generateRandomMethodName, [
				visibility = Visibility.PRIVATE
				addAnnotation(InjectedFieldsSignatureMethod.newAnnotationReference)
				// TODO change filter() to better solution
				componentModel.fieldComponentReferences.forEach [ fieldComponentReference, index |
					addParameter(fieldComponentReference.declaration.simpleName,
						fieldComponentReference.declaredTypeReference)
				]

				body = '''throw new «UnsupportedOperationException.newTypeReference»();'''
			])

			componentModel.generatedComponentReferences.forEach [ generatedComponentReference |
				componentClassDeclaration.addField(
					componentModel.getGeneratedComponentReferenceFieldName(generatedComponentReference), [
						type = generatedComponentReference.typeReference
					])
			]

			componentClassDeclaration.generateConstructor(componentModel, context)

			//
			// Process interceptors
			//
			componentModel.interceptedMethods.forEach [ interceptedMethod |
				val annotatedMutableMethod = componentClassDeclaration.findDeclaredMethod(
					interceptedMethod.methodDeclaration.simpleName, interceptedMethod.methodDeclaration.parameters.map [
						type
					])
				transformMethod(componentModel, annotatedMutableMethod, interceptedMethod.interceptorInvocations,
					context)
			]
		}
		catch (Exception e)
		{
			handleExceptions(e, context, componentClassDeclaration)
		}
	}

	def private static findGeneratedComponentConstructor(TypeReference componentClassTypeReference,
		extension TransformationContext context)
	{
		// TODO check
		componentClassTypeReference.declaredResolvedConstructors.map[declaration].filter [
			hasAnnotation(GeneratedComponentConstructor.findTypeGlobally)
		].head
	}

	def private static generateProviderConverter(ComponentReference componentReference, String inputSourceCode,
		TransformationContext context)
	{
		switch (componentReference.signature.cardinality)
		{
			case SINGLE:
				generateSingleProviderConverter(componentReference, inputSourceCode, context)
			case MULTIPLE:
				generateMultipleProviderConverter(componentReference, inputSourceCode, context)
		}
	}

	def private static generateSingleProviderConverter(ComponentReference componentReference, String inputSourceCode,
		TransformationContext context)
	{
		switch (componentReference.providerType)
		{
			case DIRECT:
			{
				val supplierCode = '''((«componentReference.signature.componentTypeSignature.typeReference.name»)((«inputSourceCode»).get()))'''
				if (!componentReference.
					optional)
				{
					'''«com.erinors.ioc.shared.impl.IocUtils.name».checkRequiredComponentReference(«supplierCode», "«componentReference.displayName»")'''
				}
				else
				{
					supplierCode
				}
			}
			case GUAVA_OPTIONAL:
			'''((«Optional.name»)(«inputSourceCode».isPresent() ? «Optional.name».fromNullable(«inputSourceCode».get()) : «Optional.name».absent()))'''
			case GUAVA_SUPPLIER:
			'''(«IocUtils.getProviderTypeReference(componentReference, context).name»)«inputSourceCode»'''
		}
	}

	def private static generateMultipleProviderConverter(ComponentReference componentReference, String inputSourceCode,
		extension TransformationContext context)
	{
		'''(«List.name»)«ImmutableList.name».copyOf(«Lists.name».transform(«inputSourceCode», new «Function.newTypeReference(componentReferenceSupplierTypeReference(componentReference.signature, context), IocUtils.getProviderTypeReference(componentReference, context)).name»() {
						public «IocUtils.getProviderTypeReference(componentReference, context).name» apply(final «componentReferenceSupplierTypeReference(componentReference.signature, context).name» e) {
							return «generateSingleProviderConverter(componentReference, "e", context)»;
						}
			}))'''
	}

	def static private componentReferenceSupplierTypeReference(ComponentReferenceSignature componentReferenceSignature,
		extension TransformationContext context)
	{
		ComponentReferenceSupplier.newTypeReference(
			componentReferenceSignature.componentTypeSignature.typeReference.wrapperIfPrimitive.
				newWildcardTypeReference)
			}

			def private generateConstructor(MutableClassDeclaration annotatedClass, ComponentClassModel componentModel,
				extension TransformationContext context)
			{
				val declaredComponentConstructor = componentModel.componentConstructor

				annotatedClass.addConstructor [
					addAnnotation(GeneratedComponentConstructor.newAnnotationReference)

					addParameter("moduleInstance", ModuleInstance.newTypeReference)

					val dependencyParameterNames = newHashMap
					componentModel.constructorParameters.forEach [ componentReferenceSignature, index |
						val parameterName = '''p«index»'''
						dependencyParameterNames.put(componentReferenceSignature, parameterName)

						val baseTypeReference = componentReferenceSupplierTypeReference(componentReferenceSignature,
							context)
						addParameter(
							parameterName,
							if (componentReferenceSignature.cardinality == CardinalityType.SINGLE)
								baseTypeReference
							else
								List.newTypeReference(baseTypeReference.wrapperIfPrimitive.newWildcardTypeReference)
						)
					]

					val superclassGeneratedComponentConstructor = if (componentModel.superclassModel !== null)
							findGeneratedComponentConstructor(componentModel.superclassModel.typeReference,
								context)
						else
							null

					body = '''
						«IF declaredComponentConstructor !== null»
							this(«FOR parameter : componentModel.constructorComponentReferences SEPARATOR ", "»«generateProviderConverter(parameter, dependencyParameterNames.get(parameter.signature), context)»«ENDFOR»);
						«ELSEIF superclassGeneratedComponentConstructor !== null»
							super(moduleInstance«IF !componentModel.superclassModel.componentReferences.empty», «ENDIF»«FOR parameter : componentModel.superclassModel.componentReferences SEPARATOR ", "»«dependencyParameterNames.get(parameter.signature)»«ENDFOR»);
						«ENDIF»
						this.«MODULE_IMPLEMENTOR_FIELD_NAME» = («ModuleImplementor.newTypeReference»)moduleInstance;
						«FOR field : componentModel.fieldComponentReferences»
							this.«field.declaration.simpleName» = «generateProviderConverter(field, dependencyParameterNames.get(field.signature), context)»;
						«ENDFOR»
						«FOR generatedComponentReference : componentModel.generatedComponentReferences»
							this.«componentModel.getGeneratedComponentReferenceFieldName(generatedComponentReference)» = «generateProviderConverter(generatedComponentReference, dependencyParameterNames.get(generatedComponentReference.signature), context)»;
						«ENDFOR»
						
						«FOR observerMethod : annotatedClass.declaredMethods.filter[findAnnotation(EventObserver.findTypeGlobally) !== null]»
							«val eventTypeReference = if (observerMethod.parameters.empty) observerMethod.findAnnotation(EventObserver.findTypeGlobally).getClassValue("eventType") else observerMethod.parameters.get(0).type»
							«val rejectSubtypes = observerMethod.findAnnotation(EventObserver.findTypeGlobally).getBooleanValue("rejectSubtypes")»
							this.«MODULE_IMPLEMENTOR_FIELD_NAME».getModuleEventBus().registerListener(«generateEventMatcherSourceCode(eventTypeReference, rejectSubtypes, context)», («Procedure1.newTypeReference») new «Procedure1.newTypeReference(eventTypeReference)»() {
								public void apply(«eventTypeReference.name» event) {
									«annotatedClass.simpleName».this.«observerMethod.simpleName»(«IF !observerMethod.parameters.empty»event«ENDIF»);
								}
							});
						«ENDFOR»
					'''
				// FIXME EventObserver validálás, pl. egy paraméter, void return type, stb. - ezt az egészet normálisan megírni
				]
			}

			def private generateEventMatcherSourceCode(TypeReference reference, boolean rejectSubtypes,
				extension TransformationContext context)
			{
				if (rejectSubtypes)
				{
					'''new «EventMatcher.newTypeReference.name»() {
					public boolean matches(Object event) {
						return event != null && event.getClass() == «reference.type.qualifiedName».class;
					}
				}'''
				}
				else
				{
					'''new «EventMatcher.newTypeReference.name»() {
					public boolean matches(Object event) {
						return event instanceof «reference.name»;
					}
				}'''
				}
			}
		}
// TODO ha nincs toString, akkor generálni egyet
// FIXME handle if provider returns null in case of component reference cardinality "multiple"
		