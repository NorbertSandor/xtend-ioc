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

import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.CodeGenerationParticipant
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsParticipant
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.ValidationContext
import org.eclipse.xtend.lib.macro.ValidationParticipant
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.Declaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableDeclaration
import org.eclipse.xtend.lib.macro.services.ProblemSupport
import java.lang.annotation.Annotation

@FinalFieldsConstructor
class AbstractSafeClassProcessor implements RegisterGlobalsParticipant<Declaration>, TransformationParticipant<MutableDeclaration>, CodeGenerationParticipant<Declaration>, ValidationParticipant<Declaration>
{
	val AbstractClassProcessor abstractComponentProcessor

	val Class<? extends Annotation> annotationClass

	val String errorCode

	override doRegisterGlobals(List<? extends Declaration> annotatedSourceElements,
		extension RegisterGlobalsContext context)
	{
		if (check(annotatedSourceElements, null))
		{
			abstractComponentProcessor.doRegisterGlobals(annotatedSourceElements as List<? extends ClassDeclaration>,
				context)
		}
	}

	override doTransform(List<? extends MutableDeclaration> annotatedTargetElements,
		extension TransformationContext context)
	{
		if (check(annotatedTargetElements, context))
		{
			abstractComponentProcessor.doTransform(annotatedTargetElements as List<? extends MutableClassDeclaration>,
				context)
		}
	}

	override doGenerateCode(List<? extends Declaration> annotatedSourceElements,
		extension CodeGenerationContext context)
	{
		if (check(annotatedSourceElements, null))
		{
			abstractComponentProcessor.doGenerateCode(annotatedSourceElements as List<? extends ClassDeclaration>,
				context)
		}
	}

	override doValidate(List<? extends Declaration> annotatedTargetElements, extension ValidationContext context)
	{
		if (check(annotatedTargetElements, null))
		{
			abstractComponentProcessor.doValidate(annotatedTargetElements as List<? extends ClassDeclaration>, context)
		}
	}

	def private check(List<? extends Declaration> declarations, ProblemSupport problemSupport)
	{
		val invalidDeclarations = declarations.filter[!(it instanceof ClassDeclaration)]
		invalidDeclarations.forEach [
			if (problemSupport != null)
			{
				problemSupport.
					addError(
						it, '''@«annotationClass.simpleName» is supported only for class declarations. [«errorCode»]''')
			}
		]
		return invalidDeclarations.empty
	}

}