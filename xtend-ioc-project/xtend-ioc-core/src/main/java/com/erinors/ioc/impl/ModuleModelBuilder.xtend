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

import com.erinors.ioc.impl.ModuleModelBuilder.ModuleModelBuilderContext
import com.erinors.ioc.shared.api.ImportComponents
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.OrderConstants
import com.erinors.ioc.shared.api.PriorityConstants
import com.erinors.ioc.shared.api.Provider
import java.util.Set
import java.util.regex.Pattern
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.file.Path

import static extension com.erinors.ioc.impl.IocUtils.*
import static extension com.erinors.ioc.impl.ProcessorUtils.*

// TODO module interface ne lehessen generikus
class ModuleModelBuilder
{
	interface ModuleModelBuilderContext
	{
		def InterfaceDeclaration getModuleInterfaceDeclaration()

		def boolean exists(ComponentTypeSignature componentTypeSignature)

		def void addComponentModel(ComponentModel componentModel)

		def void addComponentClass(TypeReference componentClassTypeReference)
	}

	val extension TransformationContext context

	val BuiltinComponentManagers builtinComponentManagers

	new(TransformationContext context)
	{
		this.context = context
		builtinComponentManagers = BuiltinComponentManagers.builtinComponentManagers(context)
	}

	// TODO check: non-abstract module interface may not have type arguments
	def build(InterfaceDeclaration moduleInterface)
	{
		val Set<TypeReference> inheritedModules = newLinkedHashSet
		val Set<ComponentClassModel> componentClassModels = newLinkedHashSet
		preprocessModule(
			moduleInterface,
			inheritedModules,
			componentClassModels
		)

		val moduleComponentReferences = collectModuleDependencies(inheritedModules +
			#[moduleInterface.newTypeReference])

		val allComponentModels = processModule(moduleInterface, componentClassModels, moduleComponentReferences)

		val moduleAnnotation = moduleInterface.findAnnotation(Module.findTypeGlobally)
		val abstract = moduleAnnotation.getBooleanValue("isAbstract")

		val singleton = moduleInterface.isSingletonModule(context)

		new StaticModuleModel(moduleInterface, abstract, singleton, inheritedModules, allComponentModels,
			moduleComponentReferences)
	}

	def private void preprocessModule(
		InterfaceDeclaration moduleInterface,
		Set<TypeReference> allInheritedModules,
		Set<ComponentClassModel> componentClassModels
	)
	{
		val moduleAnnotation = moduleInterface.findAnnotation(Module.findTypeGlobally)

		if (moduleAnnotation === null)
		{
			throw new IocProcessingException // TODO
		}

		val importedModules = moduleInterface.importedModules.map[newTypeReference]
		(moduleInterface.inheritedModules + importedModules).forEach [
			allInheritedModules.add(it)
			preprocessModule(type as InterfaceDeclaration, allInheritedModules, componentClassModels)
		]

		val componentClassTypeReferences = moduleAnnotation.getClassArrayValue("components")
		if (componentClassTypeReferences === null)
		{
			throw new CancelOperationException // TODO document case
		}

		// TODO report error: cannot rename
		val componentTypeReferences = newLinkedHashSet(componentClassTypeReferences)

		moduleAnnotation.getClassArrayValue("componentScanClasses").forEach [ componentScanClass |
			// TODO refactor based on xtend-contrib/Reflections
			context.getProjectSourceFolders(moduleInterface.compilationUnit.filePath).forEach [ sourceFolderPath |
				val componentScanPath = sourceFolderPath.append(componentScanClass.type.packageName.replace(".", "/"))
				componentTypeReferences += scanComponents(moduleInterface, sourceFolderPath, componentScanPath)
			]
		]

		moduleAnnotation.getClassArrayValue("componentImporters").forEach [ componentImporter |
			val importComponentsAnnotation = (componentImporter.type as TypeDeclaration).findAnnotation(
				ImportComponents.findTypeGlobally)
			// TODO check NPE
			importComponentsAnnotation.getClassArrayValue("value").forEach [
				componentTypeReferences += it
			]
		]

		val validationMessages = componentTypeReferences.map [
			type.validateComponentType(moduleInterface, context)
		].flatten
		if (!validationMessages.empty)
		{
			throw new IocProcessingException(validationMessages)
		}

		val moduleComponentModels = try
		{
			componentTypeReferences.map [
				new ComponentClassModelBuilder(context).build(it)
			]
		}
		catch (Exception e)
		{
			// Ignore exception
			throw new CancelOperationException
		}

		componentClassModels += moduleComponentModels
	}

	// TODO cleanup
	private def Set<? extends TypeReference> scanComponents(InterfaceDeclaration i, Path sourceFolder,
		Path componentScanRoot)
	{
		val result = <String>newLinkedHashSet
		visit(sourceFolder, componentScanRoot, result)

		return result.map[newTypeReference].toSet
	}

	// TODO cleanup
	private def void visit(Path sourceFolder, Path path, Set<String> classNames)
	{
		path.children.forEach [ currentPath |
			if (currentPath.file && currentPath.lastSegment.endsWith(".xtend"))
			{
				val relativeFilePath = sourceFolder.relativize(currentPath)
				val packageName = relativeFilePath.toString.substring(0,
					relativeFilePath.toString.length - relativeFilePath.lastSegment.length).replace('/', '.')

				val pattern = Pattern.compile('''@Component.*?\sclass\s+(\w+)''', Pattern.DOTALL)
				val fileContents = currentPath.contents
				val matcher = pattern.matcher(fileContents)
				while (matcher.find)
				{
					val className = matcher.group(1)
					classNames += packageName + className
				}
			}
			else
			{
				visit(sourceFolder, currentPath, classNames)
			}
		]
	}

	@Data
	private static class ModuleMethodSignature
	{
		val String name

		val TypeReference returnType

		val Iterable<? extends TypeReference> parameterTypes
	}

	def private collectModuleDependencies(Iterable<TypeReference> allModuleInterfaces)
	{
		allModuleInterfaces.map [
			declaredResolvedMethods
		].flatten //
		// Filter methods with same name and signature in different inherited module interfaces
		.filter[!declaration.static].groupBy [
			new ModuleMethodSignature(declaration.simpleName, declaration.returnType,
				declaration.parameters.map[type].toList)
		].mapValues[head].values //
		.map [ interfaceMethod |
			IocUtils.createDeclaredComponentReference(interfaceMethod.declaration, interfaceMethod.resolvedReturnType,
				context)
		].toSet
	}

	/**
	 * Process module 
	 */
	def private processModule(InterfaceDeclaration moduleInterface,
		Set<? extends ComponentClassModel> componentClassModels, // TODO rename
		Set<? extends DeclaredComponentReference<MethodDeclaration>> moduleComponentReferences)
	{
		val allDependencies = (componentClassModels.map[componentReferences].flatten + moduleComponentReferences).toSet.
			immutableCopy

		val Set<ComponentModel> additionalComponentModels = newLinkedHashSet

		val moduleBuilderContext = new ModuleModelBuilderContext()
		{
			override getModuleInterfaceDeclaration()
			{
				moduleInterface
			}

			override exists(ComponentTypeSignature componentTypeSignature)
			{
				componentClassModels.exists[typeSignature == componentTypeSignature]
			}

			override addComponentModel(ComponentModel componentModel)
			{
				additionalComponentModels.add(componentModel)
			}

			override addComponentClass(TypeReference componentClassTypeReference)
			{
				val componentModel = try
				{
					new ComponentClassModelBuilder(context).build(componentClassTypeReference)
				}
				catch (Exception e)
				{
					// Ignore exception
					throw new CancelOperationException
				}

				additionalComponentModels.add(componentModel)
			}
		}

		builtinComponentManagers.componentManagers.forEach [
			apply(moduleBuilderContext, moduleComponentReferences)
		]

		componentClassModels.forEach [ ownerComponentModel |
			builtinComponentManagers.componentManagers.forEach [
				apply(moduleBuilderContext, ownerComponentModel)
			]
		]

		// TODO additionalComponentModels must be processed recursively
		componentClassModels.forEach [ ownerComponentModel |
			ownerComponentModel.classDeclaration.declaredMethods.filter [
				hasAnnotation(Provider.findTypeGlobally)
			].forEach [ providerMethodDeclaration |
				processProviderMethod(providerMethodDeclaration, allDependencies, additionalComponentModels,
					ownerComponentModel)
			]
		]

		(componentClassModels + additionalComponentModels).toSet.immutableCopy
	}

	def private processProviderMethod(MethodDeclaration providerMethodDeclaration,
		Set<ComponentReference> allDependencies, Set<ComponentModel> additionalComponentModels,
		ComponentClassModel ownerComponentModel)
		{
			val providerSimpleQualifiers = providerMethodDeclaration.findComponentQualifiers(context)

			val providerAnnotation = providerMethodDeclaration.findAnnotation(Provider.findTypeGlobally)
			val providerParameterizedQualifiers = providerAnnotation.collectParameterizedQualifiers

			providerParameterizedQualifiers.forEach [ parameterizedQualifier |
				if (providerSimpleQualifiers.exists[name == parameterizedQualifier.name])
				{
					throw new IllegalStateException("invalid qualifier composition: " + parameterizedQualifier.name) // FIXME
				}
			]

			val applicableDependencies = allDependencies.filter [ componentReference |
				val componentReferenceParameterizedQualifiers = componentReference.
					componentReferenceParameterizedQualifiers(providerParameterizedQualifiers)

				if (componentReferenceParameterizedQualifiers.size != providerParameterizedQualifiers.size)
				{
					// TODO warning: no component is generated!
					false
				}
				else
				{
					val currentReferenceSyntheticSignature = new ComponentReferenceSignature(
						new ComponentTypeSignature(providerMethodDeclaration.returnType.wrapperIfPrimitive,
							(providerSimpleQualifiers + componentReferenceParameterizedQualifiers).toSet),
						componentReference.signature.cardinality
					)

					componentReference.signature.isAssignableFrom(currentReferenceSyntheticSignature)
				}
			].toSet.immutableCopy

			val finalQualifierLists = applicableDependencies.map [
				(providerSimpleQualifiers + componentReferenceParameterizedQualifiers(providerParameterizedQualifiers)).
					toSet
			].toSet.immutableCopy

			// TODO allow setting priority and order
			finalQualifierLists.forEach [ qualifiers |
				additionalComponentModels +=
					#[
						new ComponentProviderModel(
							new ComponentTypeSignature(providerMethodDeclaration.returnType, qualifiers.toSet),
							providerMethodDeclaration.getLifecycleManagerClass(context),
							PriorityConstants.DEFAULT_PRIORITY, OrderConstants.DEFAULT_ORDER, ownerComponentModel,
							providerMethodDeclaration, providerParameterizedQualifiers.toSet)]
			]
		}

		def private componentReferenceParameterizedQualifiers(ComponentReference componentReference,
			Iterable<ParameterizedQualifierModel> providerParameterizedQualifiers)
		{
			componentReference.signature.componentTypeSignature.qualifiers.filter [ qualifier |
				providerParameterizedQualifiers.exists[name == qualifier.name]
			]
		}
	}
	