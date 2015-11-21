package com.erinors.ioc.spi

import com.erinors.ioc.impl.ResolvedModuleModel
import com.erinors.ioc.impl.StaticModuleModel
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration

interface ModuleProcessorExtension
{
	def void doRegisterGlobals(InterfaceDeclaration moduleInterface, extension RegisterGlobalsContext context)

	def void doTransformNonAbstractModule(MutableInterfaceDeclaration moduleInterface, TransformationContext context,
		ResolvedModuleModel moduleModel)

	def void doTransformAbstractModule(MutableInterfaceDeclaration moduleInterface, TransformationContext context,
		StaticModuleModel moduleModel)
}

interface ComponentProcessorExtension
{
}
