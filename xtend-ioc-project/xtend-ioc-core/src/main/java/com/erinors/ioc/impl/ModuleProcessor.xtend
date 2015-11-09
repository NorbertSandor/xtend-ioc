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

import com.erinors.ioc.shared.api.ComponentLifecycleManager
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.ModuleInitializedEvent
import com.erinors.ioc.shared.impl.AbsentComponentReferenceSupplier
import com.erinors.ioc.shared.impl.AbstractModuleImplementor
import com.erinors.ioc.shared.impl.ModuleImplementor
import com.erinors.ioc.shared.impl.PresentComponentReferenceSupplier
import com.google.common.base.Optional
import com.google.common.base.Supplier
import com.google.common.base.Suppliers
import com.google.common.collect.ImmutableList
import java.io.StringWriter
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.macro.AbstractInterfaceProcessor
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtend.lib.macro.services.TypeReferenceProvider
import org.jgrapht.ext.DOTExporter
import org.jgrapht.graph.DefaultEdge

import static extension com.erinors.ioc.impl.IocUtils.*
import static extension com.erinors.ioc.impl.ProcessorUtils.*

class ModuleProcessor extends AbstractSafeInterfaceProcessor
{
	new()
	{
		super(new ModuleProcessorImplementation, Module, "E001")
	}
}

class ModuleProcessorImplementation extends AbstractInterfaceProcessor
{
	val Map<String, ResolvedModuleModel> moduleModels = newHashMap

	// TODO ezeket utilsba
	def private static String gwtEntryPointClassName(Type moduleType)
	'''«moduleType.qualifiedName»EntryPoint'''

	def private static String modulePeerClassName(TypeReference moduleType)
	'''«modulePeerClassName(moduleType.type.qualifiedName)»'''

	def private static String modulePeerClassName(String moduleQualifiedName)
	'''«moduleQualifiedName».Peer'''

	override doRegisterGlobals(InterfaceDeclaration annotatedInterface, extension RegisterGlobalsContext context)
	{
		registerClass(annotatedInterface.moduleImplementationClassName)
		registerClass(annotatedInterface.qualifiedName.modulePeerClassName)

		if (annotatedInterface.gwtEntryPoint)
		{
			registerClass(annotatedInterface.gwtEntryPointClassName)
		}
	}

	override doGenerateCode(InterfaceDeclaration annotatedInterface, extension CodeGenerationContext context)
	{
		val moduleModel = moduleModels.get(annotatedInterface.qualifiedName)
		if (moduleModel !== null)
		{
			val dependencyGraphValid = moduleModel.staticModuleModel.nonAbstract && try
			{
				moduleModel.dependencyGraph
				true
			}
			catch (Exception e)
			{
				false
			}

			val targetFolder = annotatedInterface.compilationUnit.filePath.targetFolder

			val componentIds = newHashMap
			moduleModel.staticModuleModel.components.forEach [ componentModel, index |
				componentIds.put(componentModel, (index + 1).toString)
			]

			val dotContents = if (dependencyGraphValid)
				{
					val graph = moduleModel.dependencyGraph.graph

					val writer = new StringWriter
					val dotExporter = new DOTExporter<DependencyGraphNode, DefaultEdge>([
						componentIds.get(componentModel)
					], [
						'''«componentModel.getTypeSignature.typeReference» [«componentIds.get(componentModel)»]'''
					], null)
					dotExporter.export(writer, graph)
					writer.toString.replace(System.lineSeparator, "\n")
				}

			if (dependencyGraphValid)
			{
				val dotFile = targetFolder.append(annotatedInterface.qualifiedName.replace('.', '/') + ".dot")
				dotFile.contents = '''«dotContents»'''
			}

			val reportFile = targetFolder.append(
				annotatedInterface.qualifiedName.replace('.', '/') +
					".report.html"
			)

			reportFile.contents = '''
				<!DOCTYPE html>
				<html>
				<head>
				<meta charset="UTF-8">
				<title>«annotatedInterface.simpleName» (xtend-ioc report)</title>
				<script src="https://github.com/mdaines/viz.js/releases/download/1.0.1/viz.js"></script>
				</head>
				
				<body>
					<h1>Module «annotatedInterface.simpleName»</h1>
					
					<h2>Module properties</h2>
					<dl>
						<dt>Interface</dt>
						<dd>«moduleModel.staticModuleModel.moduleInterfaceDeclaration.qualifiedName»</dd>
						<dt>«IF moduleModel.staticModuleModel.isNonAbstract»Non-abstract«ELSE»Abstract«ENDIF»</dt>
						<dd></dd>
						<dt>Inherited modules</dt>
						<dd>«IF moduleModel.staticModuleModel.inheritedModules.empty»-«ELSE»«moduleModel.staticModuleModel.inheritedModules»«ENDIF»</dd>
					</dl>
					
					«IF moduleModel.staticModuleModel.isNonAbstract»
						<h2>Components</h2>
						«FOR componentModel : moduleModel.staticModuleModel.components»«componentModel.asHtml(3, componentIds.get(componentModel))»«ENDFOR»
					«ENDIF»
					
					«IF moduleModel.staticModuleModel.isNonAbstract»
						«IF dependencyGraphValid»
							<h2>Dependency graph</h2>
							<div id="graph"></div>
							
							<script>
								var parser = new DOMParser();
								var result = Viz(«dotContents.split("\n").map["'" + it + "'"].join(" +\n")», {engine: "dot", format: "svg"});
								var svg = parser.parseFromString(result, "image/svg+xml");
								document.getElementById("graph").appendChild(svg.documentElement);
							</script>
						«ELSE»
							Invalid dependency graph!
						«ENDIF»
					«ENDIF»
				</body>
				
				</html> 
			'''
		}
	}

	def asHtml(ComponentReference<?> componentReference,
		int level)
	{
		'''<h«level»>«IF componentReference.optional»optional «ENDIF»«IF componentReference.signature.cardinality == CardinalityType.MULTIPLE»list of«ENDIF»«componentReference.signature.componentTypeSignature.asHtml(level+1)»</h«level»>'''
	}

	def asHtml(ComponentModel componentModel, int level, String componentId)
	{
		'''<h«level»>''' + switch (componentModel)
		{
			ComponentClassModel:
			'''Component class: «componentModel.classDeclaration.qualifiedName»'''
			ComponentProviderModel:
			'''Provider in «componentModel.ownerComponentModel.classDeclaration.qualifiedName»)'''
			EventComponentModel:
			'''Event of «componentModel.eventTypeReference.name»'''
			ModuleInstanceComponentModel:
			'''Module instance'''
		} + ''' [«componentId»]<h«level»>
			«componentModel.typeSignature.asHtml(level+1)»
			'''
	}

	def asHtml(ComponentTypeSignature componentTypeSignature, int level)
	{
		'''
			<div>«componentTypeSignature.typeReference.name»</div>
			«componentTypeSignature.qualifiers.asHtml(level+1)»
		'''
	}

	def asHtml(Iterable<? extends QualifierModel> qualifiers,
		int level)
	{
		'''«FOR qualifier : qualifiers BEFORE "<h"+ level +">Qualifiers</h"+level+"><div>" AFTER "</div>"»<pre>«qualifier.asString»</pre>«ENDFOR»'''
	}

	override doTransform(MutableInterfaceDeclaration annotatedInterface, extension TransformationContext context)
	{
		transformModuleInterface(annotatedInterface, context)

		try
		{
			val moduleModel = new ModuleModelBuilder(context).build(annotatedInterface)

			if (moduleModel.gwtEntryPoint)
			{
				generateGwtEntryPointClass(annotatedInterface, context)
			}

			try
			{
				if (moduleModel.isNonAbstract)
				{
					// Resolve module
					val resolvedModuleModel = moduleModel.resolve

					moduleModels.put(annotatedInterface.qualifiedName, resolvedModuleModel)

					// Build initialization graph
					resolvedModuleModel?.dependencyGraph

					// Generate module classes
					generateModulePeer(annotatedInterface, moduleModel, context, true)
					generateModuleImplementation(annotatedInterface, resolvedModuleModel, context)
				}
				else
				{
					generateModulePeer(annotatedInterface, moduleModel, context, false)
				}
			}
			catch (Exception e)
			{
				generateModulePeer(annotatedInterface, moduleModel, context, false)
				throw e
			}
		}
		catch (Exception e)
		{
			handleExceptions(e, context, annotatedInterface)
		}
	}

	def generateGwtEntryPointClass(InterfaceDeclaration moduleInterfaceDeclaration,
		extension TransformationContext context)
	{
		val gwtEntryPointDeclaration = findClass(moduleInterfaceDeclaration.gwtEntryPointClassName)

		gwtEntryPointDeclaration.implementedInterfaces = #["com.google.gwt.core.client.EntryPoint".newTypeReference]

		// TODO support non-singleton modules
		gwtEntryPointDeclaration.addMethod("onModuleLoad", [
			body = '''«moduleInterfaceDeclaration.qualifiedName.modulePeerClassName».initialize();'''
		])
	}

	def private static generateResolvedComponentReferenceSourceCode(ResolvedModuleModel moduleModel,
		ComponentReferenceSignature componentReferenceSignature, extension TransformationContext context,
		(ComponentModel)=>String componentLookup)
	{
		val resolvedComponents = componentReferenceSignature.resolve(moduleModel.
			staticModuleModel)

		switch (componentReferenceSignature.cardinality)
		{
			case MULTIPLE:
			{
				'''(«List.name»)«ImmutableList.name».of(«FOR componentModel : resolvedComponents SEPARATOR ", "»«generatePresentComponentSupplierSourceCode(context, moduleModel.staticModuleModel, componentModel, componentLookup)»«ENDFOR»)'''
			}
			case SINGLE:
			{
				val componentModel = resolvedComponents.head
				if (componentModel == null)
				{
					generateAbsentComponentSupplierSourceCode(componentReferenceSignature, context)
				}
				else
				{
					generatePresentComponentSupplierSourceCode(context, moduleModel.staticModuleModel, componentModel,
						componentLookup)
				}
			}
		}
	}

	def private static generatePresentComponentSupplierSourceCode(extension TransformationContext context,
		StaticModuleModel moduleModel, ComponentModel componentModel,
		(ComponentModel)=>String componentLookup)
		{
			'''«PresentComponentReferenceSupplier.findTypeGlobally.qualifiedName».of(«componentLookup.apply(componentModel)»)'''
		}

		def private static generateAbsentComponentSupplierSourceCode(
			ComponentReferenceSignature componentReferenceSignature,
			extension TransformationContext context)
			{
				return '''«AbsentComponentReferenceSupplier.findTypeGlobally.qualifiedName».<«componentReferenceSignature.componentTypeSignature.typeReference»>of()'''
			}

			private def generateComponentLifecycleManagerSourceCode(ClassDeclaration moduleImplementationClass,
				ResolvedModuleModel moduleModel, ComponentModel componentModel,
				TransformationContext context)
				{
					'''
						«moduleModel.componentSupplierFieldNames.get(componentModel)» = new «componentModel.lifecycleManagerClass.qualifiedName»<«componentModel.getTypeSignature.typeReference.name»>() {
						protected «componentModel.typeSignature.typeReference.name» createInstance() {
							«generateComponentInstantiatorSourceCode(moduleImplementationClass, moduleModel, componentModel, context, [moduleModel.componentSupplierFieldNames.get(it)])»
						}
						};
					'''
				}

				private def generateComponentInstantiatorSourceCode(ClassDeclaration moduleImplementationClass,
					ResolvedModuleModel moduleModel, ComponentModel componentModel, TransformationContext context,
					(ComponentModel)=>String componentLookup)
				{
					switch (componentModel)
					{
						// TODO a kódgenerálás menjen a component manager-be
						ComponentClassModel:
						{
							'''
								«componentModel.classDeclaration.qualifiedName» o = new «componentModel.classDeclaration.qualifiedName»(«moduleImplementationClass.simpleName».this«FOR componentReferenceSignature : componentModel.constructorParameters BEFORE ", " SEPARATOR ", "»
																																																	«generateResolvedComponentReferenceSourceCode(moduleModel, componentReferenceSignature, context, componentLookup)»
								«ENDFOR»);
								«FOR postConstructMethod : componentModel.postConstructMethods»
									o.«postConstructMethod.simpleName»();
								«ENDFOR»
								return o;
							'''
						}
						ComponentProviderModel:
						'''
							return «moduleModel.componentSupplierFieldNames.get(componentModel.ownerComponentModel)».get().«componentModel.providerMethodDeclaration.simpleName»(«FOR parameterDeclaration : componentModel.providerMethodDeclaration.parameters SEPARATOR ", "»«generateQualifierAttributeValueSourceCode(componentModel, parameterDeclaration.simpleName)»«ENDFOR»);
						'''
						ModuleInstanceComponentModel:
						'''
							return «moduleImplementationClass.simpleName».this;
						'''
						EventComponentModel:
						'''
							return new «componentModel.typeSignature.typeReference.name»() {
								public void fire(«componentModel.eventTypeReference.name» event) {
									«moduleImplementationClass.simpleName».this.getModuleEventBus().fire(event);
								}
							};
						'''
						default:
							throw new IllegalStateException
					}
				}

				// TODO ezmiez?
				private def generateQualifierAttributeValueSourceCode(ComponentProviderModel componentModel,
					String parameterName)
				{
					val value = componentModel.getParameterizedQualifierAttributeValue(parameterName)
					switch (value)
					{
						String:
						'''"«value»"'''
						default:
							value.toString
					}
				}

				def private TypeReference getLifecycleManagerTypeReference(
					ComponentTypeSignature componentTypeSignature, extension TypeReferenceProvider context)
				{
					ComponentLifecycleManager.newTypeReference(componentTypeSignature.typeReference)
				}

				def private generateModuleImplementation(MutableInterfaceDeclaration annotatedInterface,
					ResolvedModuleModel moduleModel, extension TransformationContext context)
				{
					val implementationClass = findClass(annotatedInterface.moduleImplementationClassName)
					implementationClass.extendedClass = AbstractModuleImplementor.newTypeReference
					implementationClass.implementedInterfaces = #[annotatedInterface.newTypeReference]

					// TODO check: csak modul interfészt lehessen extendelni
					implementationClass.docComment = '''
						Components: «moduleModel.staticModuleModel.components»
						Graph:
						«moduleModel.dependencyGraph»
					'''

					moduleModel.componentSupplierFieldNames.forEach [ componentModel, fieldName |
						implementationClass.addField(fieldName, [
							type = componentModel.getTypeSignature.getLifecycleManagerTypeReference(context)
							final = true
						])
					]

					val graphNodes = moduleModel.dependencyGraph.nodes
					val orderedComponentList = graphNodes.map[componentModel]
					val eagerComponents = orderedComponentList.filter(ComponentClassModel).filter[eager]

					implementationClass.addConstructor [
						body = '''
							super("«annotatedInterface.qualifiedName»");
							«FOR componentModel : orderedComponentList»
								«generateComponentLifecycleManagerSourceCode(implementationClass, moduleModel, componentModel, context)»
							«ENDFOR»
							«IF !eagerComponents.empty»
								
								// Initialize eager components
								«FOR componentModel : eagerComponents.sortWith(new PriorityComparator)»
									«moduleModel.componentSupplierFieldNames.get(componentModel)».get();
								«ENDFOR»
							«ENDIF»
						'''
					]

					implementationClass.addMethod("close", [
						visibility = Visibility.PUBLIC

						val orderedComponentList1 = moduleModel.dependencyGraph.nodes.map[componentModel]
						val componentsWithPredestroyCallback = orderedComponentList1.filter(ComponentClassModel).filter [
							!preDestroyMethods.empty
						]

						body = '''
							«FOR componentModel : componentsWithPredestroyCallback»
								«FOR predestroyMethod : componentModel.preDestroyMethods»
									«moduleModel.componentSupplierFieldNames.get(componentModel)».get().«predestroyMethod.simpleName»();
								«ENDFOR»
							«ENDFOR»
						'''
					])

					//
					// Generate explicit dependency methods 
					//
					moduleModel.staticModuleModel.explicitModuleDependencies.forEach [ componentReference |
						val interfaceMethodDeclaration = componentReference.declaration
						val returnType = componentReference.typeReference

						// FIXME use generateComponentReferenceSourceCode()
						implementationClass.addMethod(
							interfaceMethodDeclaration.simpleName,
							[ implementationMethod |
								// TODO implementationMethod.docComment = '''Resolved components: «componentModels»'''
								implementationMethod.returnType = returnType
								val componentReferenceSourceCode = generateExplicitModuleComponentReferenceSourceCode(
									moduleModel, componentReference, context)
								implementationMethod.body = '''return «componentReferenceSourceCode»;'''
							]
						)
					]
				}

				def private generateExplicitModuleComponentReferenceSourceCode(ResolvedModuleModel moduleModel,
					ComponentReference<?> componentReference, TransformationContext context)
				{
					val resolvedComponentReference = componentReference.resolve(moduleModel.staticModuleModel)
					generateConverter(resolvedComponentReference, moduleModel, context, [
						moduleModel.componentSupplierFieldNames.get(it)
					])
				}

				// TODO jobb nevet
				def private static generateConverter(ResolvedComponentReference<?> resolvedComponentReference,
					ResolvedModuleModel moduleModel, TransformationContext context,
					(ComponentModel)=>String componentLookup)
					{
						val resolvedComponents = resolvedComponentReference.resolvedComponents
						val componentReference = resolvedComponentReference.componentReference

						switch (componentReference.signature.cardinality)
						{
							case SINGLE:
								if (resolvedComponents.empty)
									generateSingleAbsentConverter(componentReference)
								else
									generateSinglePresentConverter(componentReference, resolvedComponents.head,
										moduleModel, context,
										componentLookup)
								case MULTIPLE:
								'''(«List.name»)«ImmutableList.name».of(«FOR componentModel : resolvedComponents SEPARATOR ", "»«generateSinglePresentConverter(componentReference, componentModel, moduleModel, context, componentLookup)»«ENDFOR»)'''
							}
						}

						def private static generateSingleAbsentConverter(ComponentReference<?> componentReference)
						{
							switch (componentReference.providerType)
							{
								case DIRECT:
									"null"
								case GUAVA_SUPPLIER:
								'''(«Supplier.name»)«Suppliers.name».ofInstance(null)'''
								case GUAVA_OPTIONAL:
								'''(«Optional.name»)«Optional.name».absent()'''
							}
						}

						def private static generateSinglePresentConverter(ComponentReference<?> componentReference,
							ComponentModel componentModel, ResolvedModuleModel moduleModel,
							TransformationContext context, (ComponentModel)=>String componentLookup)
						{
							val componentFieldName = componentLookup.apply(componentModel)
							switch (componentReference.providerType)
							{
								case DIRECT:
								'''«componentFieldName».get()'''
								case GUAVA_SUPPLIER:
								'''(«Supplier.name»)«componentFieldName»'''
								case GUAVA_OPTIONAL:
								'''(«Optional.name»)«Optional.name».of(«componentFieldName».get())'''
							}
						}

						def private generateModulePeer(MutableInterfaceDeclaration annotatedInterface,
							StaticModuleModel moduleModel, extension TransformationContext context, boolean validGraph)
						{
							val peerClass = findClass(annotatedInterface.qualifiedName.modulePeerClassName)

							if (moduleModel.singleton)
							{
								// TODO this should not be publicly available
								peerClass.addField("moduleInstance", [
									static = true
									visibility = Visibility.PUBLIC
									type = annotatedInterface.newTypeReference
								])

								peerClass.addMethod("get", [
									static = true
									visibility = Visibility.PUBLIC
									returnType = annotatedInterface.newTypeReference
									body = '''
										«annotatedInterface.newTypeReference» moduleInstance = «peerClass.qualifiedName».moduleInstance;
										
										if (moduleInstance == null) {
											throw new «IllegalStateException.name»("Module is not initialized, initialize() should be called!");
										}
										return moduleInstance;
									'''
								])

								peerClass.addMethod("initialize", [
									static = true
									visibility = Visibility.PUBLIC

									addParameter(
										"instance",
										annotatedInterface.
											newTypeReference
									)

									body = '''
										if («peerClass.qualifiedName».moduleInstance != null) {
											throw new «IllegalStateException.name»("Module is already initialized by " + «peerClass.qualifiedName».moduleInstance.getModuleInitializerInfo());
										}
										
										«peerClass.qualifiedName».moduleInstance = instance;
									'''
								])

								// TODO ez a moduleimplementor.close()-ban legyen
								peerClass.addMethod("close", [
									static = true
									visibility = Visibility.
										PUBLIC
									body = '''
										«peerClass.qualifiedName».moduleInstance.close();
										
										«FOR inheritedModule : moduleModel.inheritedModules.filter[isSingletonModule(type as InterfaceDeclaration, context)]»
											«inheritedModule.modulePeerClassName».moduleInstance = null;
										«ENDFOR»
										«peerClass.qualifiedName».moduleInstance = null;
									'''
								])

								if (moduleModel.nonAbstract)
								{
									peerClass.addMethod("initialize", [
										static = true
										visibility = Visibility.PUBLIC
										returnType = annotatedInterface.
											newSelfTypeReference
										body = if (validGraph)
										'''
											if («peerClass.qualifiedName».moduleInstance != null) {
												throw new «IllegalStateException.name»("Module is already initialized by " + «peerClass.qualifiedName».moduleInstance.getModuleInitializerInfo());
											}
											
											«peerClass.qualifiedName».moduleInstance = new «annotatedInterface.moduleImplementationClassName»();
											
											«FOR inheritedModule : moduleModel.inheritedModules.filter[isSingletonModule(type as InterfaceDeclaration, context)]»
												«inheritedModule.modulePeerClassName».initialize(«peerClass.qualifiedName».moduleInstance);
											«ENDFOR»
											
											«peerClass.qualifiedName».moduleInstance.getModuleEventBus().fire(new «ModuleInitializedEvent.name»());
											
											
											return «peerClass.qualifiedName».moduleInstance;
										'''
										else
										'''throw new «UnsupportedOperationException.name»();'''
									])
								}
							}
							else
							{
								if (moduleModel.nonAbstract)
								{
									// TODO elég nagy a hasonlóság ez és a singleton initialize() között
									peerClass.addMethod("constructInstance", [
										static = true
										visibility = Visibility.PUBLIC
										returnType = annotatedInterface.
											newSelfTypeReference
										body = if (validGraph)
										'''
											«annotatedInterface.newSelfTypeReference» instance= new «annotatedInterface.moduleImplementationClassName»();
											
											«FOR inheritedModule : moduleModel.inheritedModules.filter[isSingletonModule(type as InterfaceDeclaration, context)]»
												«inheritedModule.modulePeerClassName».initialize(instance);
											«ENDFOR»
											
											instance.getModuleEventBus().fire(new «ModuleInitializedEvent.name»());
											return instance;
										'''
										else
										'''throw new «UnsupportedOperationException.name»();'''
									])
								}
							}
						}

						def private transformModuleInterface(MutableInterfaceDeclaration annotatedInterface,
							extension TransformationContext context)
						{
							annotatedInterface.extendedInterfaces = annotatedInterface.extendedInterfaces +
								#[ModuleImplementor.newTypeReference]
						}
					}
