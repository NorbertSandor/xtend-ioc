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

import com.erinors.ioc.shared.api.GwtModule
import com.erinors.ioc.spi.ModuleProcessorExtension
import de.oehme.xtend.contrib.Buildable
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration

import static extension com.erinors.ioc.impl.GwtModuleModelBuilderUtils.*
import static extension com.erinors.ioc.impl.IocUtils.*
import static extension com.erinors.ioc.impl.ProcessorUtils.*
import static extension com.erinors.ioc.server.util.IterableUtils.*

@Data
@Buildable
package class GwtModuleModel
{
	String entryPointClassName

	Iterable<String> inherits

	def isEntryPoint()
	{
		entryPointClassName !== null
	}
}

package class GwtModuleModelBuilderUtils
{
	def static getGwtModuleAnnotation(InterfaceDeclaration interfaceDeclaration)
	{
		interfaceDeclaration.getAnnotation(GwtModule.name)
	}

	def static isGwtEntryPoint(InterfaceDeclaration moduleInterface)
	{
		moduleInterface.gwtModuleAnnotation?.getBooleanValue("entryPoint")
	}

	def static String gwtEntryPointClassName(InterfaceDeclaration moduleInterface)
	'''«moduleInterface.qualifiedName»EntryPoint'''

	def static String gwtModuleName(InterfaceDeclaration moduleInterface)
	{
		val packageName = ProcessorUtils.getPackageName(moduleInterface)
		'''«packageName.substring(0, packageName.lastIndexOf("."))».«moduleInterface.simpleName»'''
	}
}

package class GwtModuleModelBuilder
{
	def GwtModuleModel build(StaticModuleModel staticModuleModel)
	{
		val currentGwtModuleAnnotation = staticModuleModel.moduleInterfaceDeclaration.gwtModuleAnnotation
		if (currentGwtModuleAnnotation === null)
		{
			null
		}
		else
		{
			GwtModuleModel.build [
				entryPointClassName = if (currentGwtModuleAnnotation.getBooleanValue("entryPoint"))
					staticModuleModel.moduleInterfaceDeclaration.gwtEntryPointClassName
				else
					null
				// TODO include only directly inherited modules
				inherits = (staticModuleModel.inheritedModules.map[type].castElements(InterfaceDeclaration).filter [
					gwtModuleAnnotation !== null
				].map [
					gwtModuleName
				] + currentGwtModuleAnnotation.getStringArrayValue("inherits")).toSet.immutableCopy
			]
		}
	}
}

class GwtModuleProcessor implements ModuleProcessorExtension
{
	override doRegisterGlobals(InterfaceDeclaration moduleInterface, extension RegisterGlobalsContext context)
	{
		if (moduleInterface.isGwtEntryPoint)
		{
			registerClass(moduleInterface.gwtEntryPointClassName)
		}
	}

	override doTransform(MutableInterfaceDeclaration moduleInterface, TransformationContext context,
		StaticModuleModel moduleModel)
	{
		val gwtModuleModel = new GwtModuleModelBuilder().build(moduleModel)
		if (gwtModuleModel !== null)
		{
			if (gwtModuleModel.entryPoint)
			{
				generateGwtEntryPointClass(moduleInterface, context)
			}
		}
	}

	override doTransform(MutableInterfaceDeclaration moduleInterface, TransformationContext context,
		ResolvedModuleModel moduleModel)
	{
		doTransform(moduleInterface, context, moduleModel.staticModuleModel)
	}

	def private generateGwtEntryPointClass(InterfaceDeclaration moduleInterface,
		extension TransformationContext context)
	{
		val gwtEntryPointDeclaration = findClass(moduleInterface.gwtEntryPointClassName)

		gwtEntryPointDeclaration.implementedInterfaces = #["com.google.gwt.core.client.EntryPoint".newTypeReference]

		// TODO support non-singleton modules
		gwtEntryPointDeclaration.addMethod("onModuleLoad", [
			body = '''«moduleInterface.qualifiedName.modulePeerClassName».initialize();'''
		])
	}

	override doGenerateCode(InterfaceDeclaration moduleInterface, extension CodeGenerationContext context,
		ResolvedModuleModel moduleModel)
	{
		doGenerateCode(moduleInterface, context, moduleModel.staticModuleModel)
	}

	override doGenerateCode(InterfaceDeclaration moduleInterface, extension CodeGenerationContext context,
		StaticModuleModel moduleModel)
	{
		val gwtModuleModel = new GwtModuleModelBuilder().build(moduleModel)
		if (gwtModuleModel !== null)
		{
			val gwtXmlContents = '''
				<?xml version="1.0" encoding="UTF-8"?>
				<module rename-to="app">
				
					<inherits name="org.eclipse.xtext.xbase.lib.Lib" />
					<inherits name="com.erinors.ioc.Ioc" />
					
					«FOR inherits : gwtModuleModel.inherits»
						<inherits name="«inherits»" />
					«ENDFOR»
					
					<source path="client" />
					<source path="shared" />
					
					«IF gwtModuleModel.entryPoint»
						<entry-point class="«gwtModuleModel.entryPointClassName»" />
					«ENDIF»
				
				</module>
			'''

			val targetFolder = moduleInterface.compilationUnit.filePath.targetFolder
			val gwtXmlFilePath = targetFolder.append('''«moduleInterface.gwtModuleName.replace('.', '/')».gwt.xml''')
			gwtXmlFilePath.contents = gwtXmlContents
		}
	}
}
