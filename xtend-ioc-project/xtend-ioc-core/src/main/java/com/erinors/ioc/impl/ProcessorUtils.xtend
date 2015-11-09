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

import com.erinors.ioc.shared.api.Module
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.AnnotationTarget
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Declaration
import org.eclipse.xtend.lib.macro.declaration.Element
import org.eclipse.xtend.lib.macro.declaration.ExecutableDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MemberDeclaration
import org.eclipse.xtend.lib.macro.declaration.ParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.Problem
import org.eclipse.xtend.lib.macro.services.Tracability
import com.erinors.ioc.shared.api.GwtEntryPoint

@Data
class ProcessingMessage
{
	Problem.Severity severity

	Element element

	String message
}

class ProcessorUtils
{
	def static isGwtEntryPoint(InterfaceDeclaration interfaceDeclaration)
	{
		interfaceDeclaration.hasAnnotation(GwtEntryPoint.name)
	}

	def static hasAnnotation(AnnotationTarget annotationTarget, String annotationQualifiedName)
	{
		annotationTarget.annotations.exists[annotationTypeDeclaration.qualifiedName == annotationQualifiedName]
	}

	// TODO nem jó helyen
	def static isSingletonModule(InterfaceDeclaration moduleDeclaration, extension TransformationContext context)
	{
		val moduleAnnotation = moduleDeclaration.getAnnotation(Module.findTypeGlobally)

		if (moduleAnnotation == null)
		{
			throw new IllegalStateException('''Not a module declaration: «moduleDeclaration.qualifiedName»''')
		}

		moduleAnnotation.getBooleanValue("singleton")
	}

	def static findDefaultConstructor(ClassDeclaration classDeclaration, extension Tracability tracability)
	{
		val constructor = classDeclaration.declaredConstructors.filter[parameters.empty].head
		if (constructor != null && !constructor.isThePrimaryGeneratedJavaElement)
			constructor
		else
			null
	}

	def static boolean hasAnnotation(AnnotationTarget annotationTarget, Type annotationType)
	{
		annotationTarget.getAnnotation(annotationType) != null
	}

	def static AnnotationReference getAnnotation(AnnotationTarget annotationTarget, Type annotationType)
	{
		annotationTarget.findAnnotation(annotationType)
	}

	def static String getPackageName(Type type)
	{
		val qualifiedName = type.qualifiedName
		if (qualifiedName.contains("."))
			qualifiedName.substring(0, type.qualifiedName.lastIndexOf('.'))
		else
			""
	}

	def static toDisplayName(Element element)
	{
		switch (element)
		{
			Declaration: element.asString
			default: element.toString
		}
	}

	def static String asString(Element element)
	{
		switch (element)
		{
			TypeDeclaration:
				element.qualifiedName
			ExecutableDeclaration:
			'''«element.declaringType.simpleName».«element.simpleName»()'''
			MemberDeclaration:
			'''«element.declaringType.simpleName».«element.simpleName»'''
			ParameterDeclaration:
			'''parameter '«element.simpleName»' of «element.type.simpleName»'''
			default:
				element.toString
		}
	}

	// TODO nem jó helyen
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

	// TODO nem jó helyen
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

	def static hasSuperclass(TypeReference typeReference)
	{
		typeReference.superclass !== null && typeReference.superclass.name != Object.name
	}

	def static getSuperclass(TypeReference typeReference)
	{
		typeReference.declaredSuperTypes.findFirst[type instanceof ClassDeclaration]
	}

	def static generateRandomMethodName(TypeDeclaration typeDeclaration)
	{
		var String randomName
		do
		{
			randomName = "_" + Long.toHexString(Double.doubleToLongBits(Math.random()));
		}
		while (typeDeclaration.declaredMethods.map[simpleName].toSet.contains(randomName))

		return randomName
	}
}
