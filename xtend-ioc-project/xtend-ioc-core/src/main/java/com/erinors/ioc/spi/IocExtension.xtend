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
package com.erinors.ioc.spi

import com.erinors.ioc.impl.ResolvedModuleModel
import com.erinors.ioc.impl.StaticModuleModel
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration

interface ModuleProcessorExtension
{
	def void doRegisterGlobals(InterfaceDeclaration moduleInterface, extension RegisterGlobalsContext context)

	def void doTransform(MutableInterfaceDeclaration moduleInterface, extension TransformationContext context,
		ResolvedModuleModel moduleModel)

	def void doTransform(MutableInterfaceDeclaration moduleInterface, extension TransformationContext context,
		StaticModuleModel moduleModel)

	def void doGenerateCode(InterfaceDeclaration moduleInterface, extension CodeGenerationContext context,
		ResolvedModuleModel moduleModel)

	def void doGenerateCode(InterfaceDeclaration moduleInterface, extension CodeGenerationContext context,
		StaticModuleModel moduleModel)
}

interface ComponentProcessorExtension
{
}
