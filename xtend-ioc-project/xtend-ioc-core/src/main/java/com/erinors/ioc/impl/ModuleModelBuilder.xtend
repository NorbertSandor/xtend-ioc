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

import com.erinors.ioc.impl.IocUtils.ParameterizedQualifierReference
import com.erinors.ioc.impl.ModuleModelBuilder.ModuleModelBuilderContext
import com.erinors.ioc.shared.api.ImportComponents
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.PriorityConstants
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.impl.ModuleImplementor
import com.erinors.ioc.shared.impl.ModuleInstance
import com.google.common.collect.Lists
import java.util.List
import java.util.Set
import java.util.regex.Pattern
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.file.Path
import org.eclipse.xtend.lib.macro.services.Problem.Severity

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
	}

	val extension TransformationContext context

	val BuiltinComponentManagers builtinComponentManagers

	new(TransformationContext context)
	{
		this.context = context
		builtinComponentManagers = BuiltinComponentManagers.builtinComponentManagers(context)
	}

	def build(InterfaceDeclaration moduleInterface)
	{
		val Set<TypeReference> inheritedModules = newLinkedHashSet
		val Set<ComponentClassModel> componentClassModels = newLinkedHashSet
		preprocessModule(
			moduleInterface,
			inheritedModules,
			componentClassModels
		)

		// TODO non-abstract module interface may not have type arguments
		val moduleDependencies = collectModuleDependencies(moduleInterface)

		val allComponentModels = processModule(moduleInterface, componentClassModels, moduleDependencies)

		val moduleAnnotation = moduleInterface.findAnnotation(Module.findTypeGlobally)
		val abstract = moduleAnnotation.getBooleanValue("isAbstract")

		val singleton = moduleInterface.isSingletonModule(context)

		val gwtEntryPoint = moduleInterface.isGwtEntryPoint()

		new StaticModuleModel(moduleInterface, abstract, singleton, gwtEntryPoint, inheritedModules, allComponentModels,
			moduleDependencies)
	}

	def private void preprocessModule(
		InterfaceDeclaration moduleInterface,
		Set<TypeReference> inheritedModules,
		Set<ComponentClassModel> componentClassModels
	)
	{
		moduleInterface.extendedInterfaces.filter[type != ModuleImplementor.newTypeReference.type].forEach [
			inheritedModules.add(it)
			preprocessModule(type as InterfaceDeclaration, inheritedModules, componentClassModels)
		]

		val moduleAnnotation = moduleInterface.findAnnotation(Module.findTypeGlobally)

		if (moduleAnnotation != null)
		{
			val componentClassTypeReferences = moduleAnnotation.getClassArrayValue("components")
			if (componentClassTypeReferences == null)
			{
				throw new CancelOperationException
			}

			// TODO report error: cannot rename
			val componentTypeReferences = newLinkedHashSet(componentClassTypeReferences)

			moduleAnnotation.getClassArrayValue("componentScanClasses").forEach [ componentScanClass |
				// TODO refactor based on xtend-contrib/Reflections
				context.getProjectSourceFolders(moduleInterface.compilationUnit.filePath).forEach [ sourceFolderPath |
					val componentScanPath = sourceFolderPath.append(
						componentScanClass.type.packageName.replace(".", "/"))
					componentTypeReferences += scanComponents(moduleInterface, sourceFolderPath, componentScanPath)
				]
			]

			moduleAnnotation.getClassArrayValue("componentImporters").forEach [ componentImporter |
				// TODO check
				val importComponentsAnnotation = (componentImporter.type as TypeDeclaration).findAnnotation(
					ImportComponents.findTypeGlobally)
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
				// Ignore exception, ComponentProcessor should handle them
				throw new CancelOperationException
			}

			componentClassModels += moduleComponentModels
		}
		else
		{
			// TODO nem kéne hibát jelezni?
		}
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

	def private collectModuleDependencies(InterfaceDeclaration moduleInterfaceDeclaration)
	{
		moduleInterfaceDeclaration.allAssignableInterfaces(context).filter [
			it != ModuleImplementor.newTypeReference && it != ModuleInstance.newTypeReference
		].map [
			declaredResolvedMethods
		].flatten.map [ interfaceMethod |
			createDependencyReference(interfaceMethod.declaration, interfaceMethod.resolvedReturnType, context)
		].toSet
	}

	/**
	 * Process module 
	 */
	def private processModule(InterfaceDeclaration moduleInterface,
		Set<? extends ComponentClassModel> componentClassModels,
		Set<? extends ComponentReference<?>> moduleDependencies)
		{
			val allDependencies = (componentClassModels.map[componentReferences].flatten + moduleDependencies).toSet

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
			}

			componentClassModels.forEach [ ownerComponentModel |
				allDependencies.forEach [ componentReference |
					val componentManager = builtinComponentManagers.findFor(moduleBuilderContext, componentReference)
					if (componentManager != null)
					{
						componentManager.processComponentReference(moduleBuilderContext, ownerComponentModel,
							componentReference)
					}
				]
			]

			componentClassModels.forEach [ ownerComponentModel |
				ownerComponentModel.classDeclaration.declaredMethods.filter [
					hasAnnotation(Provider.findTypeGlobally)
				].forEach [ providerMethodDeclaration |
					if (providerMethodDeclaration.returnType.inferred)
					{
						// TODO ezt a componentprocessor-nak kellene vizsgálni
						throw new IocProcessingException(
							new ProcessingMessage(
								Severity.
									ERROR,
								providerMethodDeclaration,
								'''Provider method must have an explicit return type, type inference is not supported: «providerMethodDeclaration.asString»'''
							))
					}

					val providerSimpleQualifiers = providerMethodDeclaration.findQualifiers(context)

					val providerAnnotation = providerMethodDeclaration.findAnnotation(Provider.findTypeGlobally)
					val providerParameterizedQualifiers = providerAnnotation.collectParameterizedQualifiers

					providerParameterizedQualifiers.forEach [ parameterizedQualifier |
						val providerQualifiersWithAttributes = providerSimpleQualifiers.filter[hasAttributes]
						if (providerQualifiersWithAttributes.exists[name == parameterizedQualifier.name])
						{
							throw new IllegalStateException("invalid qualifier composition: " +
								parameterizedQualifier.name) // FIXME
						}
					]

					val applicableDependencies = allDependencies.filter [
						val dependencySimpleQualifiers = signature.componentTypeSignature.qualifiers.filter [ dependencyQualifier |
							!providerParameterizedQualifiers.exists[name == dependencyQualifier.name]
						].toSet
						providerSimpleQualifiers.containsAll(dependencySimpleQualifiers)
					].filter [
						val dependencyParameterizedQualifiers = signature.componentTypeSignature.qualifiers.filter [ dependencyQualifier |
							providerParameterizedQualifiers.exists[name == dependencyQualifier.name]
						].toSet
						providerParameterizedQualifiers.map[name].containsAll(dependencyParameterizedQualifiers.map [
							name
						].toSet)
					]

					val applicableParameterizedQualifierReferences = applicableDependencies.map [
						signature.componentTypeSignature.qualifiers
					].flatten.toSet.map [ qualifier |
						new ParameterizedQualifierReference(providerParameterizedQualifiers.findFirst [
							name == qualifier.name
						], qualifier)
					].groupBy[parameterizedQualifier].values.toList

					val finalizedParameterizedQualifierInstances = applicableParameterizedQualifierReferences.
						variations.map [
							map [referencingQualifier]
						].toList

					val finalQualifierLists = if (finalizedParameterizedQualifierInstances.empty)
							#[providerSimpleQualifiers]
						else
							finalizedParameterizedQualifierInstances.map [
								it + providerSimpleQualifiers
							]

					finalQualifierLists.forEach [ qualifierVariation |
						additionalComponentModels +=
							#[
								new ComponentProviderModel(
									new ComponentTypeSignature(providerMethodDeclaration.returnType,
										qualifierVariation.toSet),
									providerMethodDeclaration.getLifecycleManagerClass(context),
									PriorityConstants.DEFAULT_PRIORITY, ownerComponentModel, providerMethodDeclaration,
									providerParameterizedQualifiers.toSet)]
					]
				]
			]

			(componentClassModels + additionalComponentModels).toSet.immutableCopy
		}

		def private static <T> Iterable<List<T>> variations(Iterable<List<T>> lists)
		{
			if (lists.empty)
				#[]
			else
			{
				val result = <List<T>>newLinkedList
				lists.head.forEach [ head |
					val rest = variations(lists.tail.toList)

					if (rest.empty)
						result.add(#[head])
					else
						rest.forEach [ tail |
							result.add(Lists.asList(head, tail))
						]
				]
				result
			}
		}
	}
