/*
 * #%L
 * xtend-ioc-core
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.impl

import com.erinors.ioc.shared.api.InvocationContext
import de.oehme.xtend.contrib.SignatureHelper
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration

class InterceptorUtils
{
	def static MutableMethodDeclaration transformMethod(ComponentClassModel componentModel,
		MutableMethodDeclaration annotatedMethod,
		Iterable<? extends InterceptorInvocationModel> interceptorInvocationModels, TransformationContext context)
	{
		return transformMethod(componentModel, annotatedMethod, interceptorInvocationModels, context,
			new SignatureHelper(context), annotatedMethod)
	}

	def private static MutableMethodDeclaration transformMethod(ComponentClassModel componentModel,
		MutableMethodDeclaration annotatedMethod,
		Iterable<? extends InterceptorInvocationModel> interceptorInvocationModels, TransformationContext context,
		SignatureHelper signatureHelper, MethodDeclaration interceptedMethodDeclaration)
	{
		if (interceptorInvocationModels.empty)
		{
			return annotatedMethod
		}

		var addedMethod = transformMethod(componentModel, annotatedMethod, interceptorInvocationModels.head, context,
			signatureHelper, interceptedMethodDeclaration)
		addedMethod.markAsRead

		return transformMethod(componentModel, addedMethod, interceptorInvocationModels.tail, context, signatureHelper,
			interceptedMethodDeclaration)
	}

	def private static MutableMethodDeclaration transformMethod(ComponentClassModel componentModel,
		MutableMethodDeclaration annotatedMethod, InterceptorInvocationModel interceptorInvocationModel,
		TransformationContext context, SignatureHelper signatureHelper, MethodDeclaration interceptedMethodDeclaration)
	{
		annotatedMethod.markAsRead

		val handlerAccessorSourceCode = componentModel.getGeneratedComponentReferenceFieldName(
			interceptorInvocationModel.invocationHandlerReference)

		val methodName = ProcessorUtils.generateRandomMethodName(annotatedMethod.declaringType)
		return signatureHelper.addIndirection(annotatedMethod,
			methodName, '''
				final Object[] inputArguments = new Object[] {«FOR parameter : annotatedMethod.parameters SEPARATOR ", "»«parameter.simpleName»«ENDFOR»};
				
				final «interceptorInvocationModel.definitionModel.invocationPointConfigurationClassName» invocationPointConfiguration = new «interceptorInvocationModel.definitionModel.invocationPointConfigurationClassName»("«interceptedMethodDeclaration.simpleName»"«FOR argument : interceptorInvocationModel.arguments BEFORE ", " SEPARATOR ", "»«argument.generateSourceCode(context)»«ENDFOR»);
				
				«IF !annotatedMethod.returnType.void»return («annotatedMethod.returnType.type.qualifiedName») «ENDIF»«handlerAccessorSourceCode».handle(invocationPointConfiguration, new «InvocationContext.name»() {
					public Object getTarget() {
						return «annotatedMethod.declaringType.qualifiedName».this;
					}
				
					public Object[] getArguments() {
						return inputArguments;
					}
				
					public Object proceed() {
						return proceed(inputArguments);
					}
					
					public Object proceed(Object[] arguments) {
						«IF !annotatedMethod.returnType.void»return «ENDIF»«methodName»(«FOR parameter : annotatedMethod.parameters SEPARATOR ", "»«parameter.simpleName»«ENDFOR»);
						«IF annotatedMethod.returnType.void»return null;«ENDIF»
					}
				});
			''')
	}

	def static invocationPointConfigurationClassName(AnnotationTypeDeclaration annotatedAnnotationType)
	{
		annotatedAnnotationType.qualifiedName + "InvocationPointConfiguration"
	}
}