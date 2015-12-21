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

import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.MethodReference
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.Problem.Severity

import static extension com.erinors.ioc.impl.IocUtils.*
import static extension com.erinors.ioc.impl.ProcessorUtils.*

@FinalFieldsConstructor
class InterceptorDefinitionModelBuilder
{
	val extension TransformationContext context

	def build(AnnotationTypeDeclaration annotationTypeDeclaration)
	{
		val interceptorAnnotation = annotationTypeDeclaration.getAnnotation(Interceptor.findTypeGlobally)

		val handlerTypeReference = interceptorAnnotation.getClassValue("value")

		if (handlerTypeReference === null)
		{
			throw new CancelOperationException
		}

		if (!handlerTypeReference.isComponentClass)
		{
			throw new IocProcessingException(
				new ProcessingMessage(Severity.ERROR,
					annotationTypeDeclaration, '''Interceptor invocation handler type must be a component class.'''))
		}

		val parameters = annotationTypeDeclaration.declaredAnnotationTypeElements.map [ attributeDeclaration |
			val parameterType = if (attributeDeclaration.hasAnnotation(MethodReference.name))
				{
					if (attributeDeclaration.type != String.newTypeReference)
					{
						throw new IocProcessingException(
							new ProcessingMessage(Severity.ERROR,
								attributeDeclaration, '''Method reference attribute must be of the String.'''))
					}

					val methodReferenceAnnotationType = MethodReference.findTypeGlobally as AnnotationTypeDeclaration
					val methodReferenceAnnotation = attributeDeclaration.getAnnotation(methodReferenceAnnotationType)

					val returnType = methodReferenceAnnotation.getClassValue("returnType")
					val parameterTypes = methodReferenceAnnotation.getClassArrayValue("parameterTypes")
					val sampleDeclaringType = methodReferenceAnnotation.getClassValue("sampleDeclaringType")
					val sampleDeclaredMethodNameSpecified = methodReferenceAnnotation.getStringValue(
						"sampleDeclaredMethodName")

					val returnTypeExplicit = returnType !=
						methodReferenceAnnotationType.findDeclaredAnnotationTypeElement("returnType").defaultValue
					val sampleDeclaringTypeExplicit = sampleDeclaringType !=
						methodReferenceAnnotationType.findDeclaredAnnotationTypeElement("sampleDeclaringType").
							defaultValue
 					val sampleDeclaredMethodNameExplicit = sampleDeclaredMethodNameSpecified !=
								methodReferenceAnnotationType.
									findDeclaredAnnotationTypeElement("sampleDeclaredMethodName").defaultValue

							val definitionByMethodSignature = returnTypeExplicit && !sampleDeclaringTypeExplicit &&
								!sampleDeclaredMethodNameExplicit
							val definitionBySample = !returnTypeExplicit && sampleDeclaringTypeExplicit

							if (!(definitionByMethodSignature || definitionBySample))
							{
								throw new IocProcessingException(
									new ProcessingMessage(Severity.ERROR,
										attributeDeclaration, '''Invalid method reference, either 'returnType' and 'parameterTypes', or 'sampleDeclaringType' and optionally 'sampleDeclaredMethodName' must be specified.'''))
							}

							val sampleDeclaredMethodName = if (definitionBySample)
								{
									if (sampleDeclaredMethodNameExplicit)
									{
										if (sampleDeclaringType.declaredResolvedMethods.filter [
											declaration.simpleName == sampleDeclaredMethodNameSpecified
										].size != 1)
										{
											throw new IocProcessingException(
												new ProcessingMessage(Severity.ERROR,
													attributeDeclaration, '''Multiple methods found with the specified name.'''))
										}
										else
										{
											sampleDeclaredMethodNameSpecified
										}
									}
									else
									{
										if (sampleDeclaringType.declaredResolvedMethods.size != 1)
										{
											throw new IocProcessingException(
												new ProcessingMessage(Severity.ERROR,
													attributeDeclaration, '''Expected exactly one method in «sampleDeclaringType.asString».'''))
										}
										else
										{
											sampleDeclaringType.declaredResolvedMethods.head.declaration.simpleName
										}
									}
								}

							// TODO more check when using sample method									
							val finalReturnType = if (definitionByMethodSignature)
									returnType
								else
									sampleDeclaringType.declaredResolvedMethods.findFirst [
										declaration.simpleName == sampleDeclaredMethodName
									].resolvedReturnType
							val finalParameterTypes = if (definitionByMethodSignature)
									parameterTypes.toList
								else
									sampleDeclaringType.declaredResolvedMethods.findFirst [
										declaration.simpleName == sampleDeclaredMethodName
									].resolvedParameters.map[declaration.type].toList

							if (finalParameterTypes.size > 6)
							{
								throw new IocProcessingException(
									new ProcessingMessage(Severity.ERROR,
										attributeDeclaration, '''Referenced methods may have at most 6 parameters.''')) // TODO
							}

							new MethodReferenceInterceptorParameterType(finalReturnType, finalParameterTypes)
						}
						else
						{
							new BasicInterceptorParameterType(attributeDeclaration.type)
						}

					new InterceptorParameterModel(attributeDeclaration.simpleName, parameterType)
				]
				new InterceptorDefinitionModel(annotationTypeDeclaration,
					InterceptorUtils.invocationPointConfigurationClassName(annotationTypeDeclaration),
					parameters.toList)
				}
			}
			