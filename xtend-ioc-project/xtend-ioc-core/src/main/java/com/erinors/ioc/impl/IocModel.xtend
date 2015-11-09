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

import de.oehme.xtend.contrib.Cached
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.ConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.Declaration
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.ParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.Problem.Severity
import org.jgrapht.alg.cycle.SzwarcfiterLauerSimpleCycles
import org.jgrapht.experimental.dag.DirectedAcyclicGraph
import org.jgrapht.graph.DefaultDirectedGraph
import org.jgrapht.graph.DefaultEdge

// TODO @Optional az Option<>-ön legyen warning, mivel redundáns
// FIXME @Component nem működik class szintű @Accessors-sal!!!! com.erinors.ioc.examples.docs.events.EventObserver nem fordul, ha @Accessors van a class-on
// TODO parameterized should support enum 
// TODO parameterized should support multiple parameter mappings 
// FIXME component classes must be annotated with @Component
// FIXME component class-nál a konstruktor paramétereken ne lehessen @Inject
// FIXME detect recursion during component initialization
// FIXME filter(Class) -> as inline for GWT support
class CancelOperationException extends RuntimeException
{
}

@FinalFieldsConstructor
class IocProcessingException extends RuntimeException
{
	@Accessors
	val Iterable<ProcessingMessage> messages

	new(ProcessingMessage... messages)
	{
		this(messages.toList)
	}
}

interface HasPriority
{
	def int getPriority()
}

@Data
class QualifierModel
{
	String name

	Map<String, ?> attributes

	def hasAttributes()
	{
		!attributes.empty
	}

	def String asString()
	'''@«name»«IF hasAttributes»«attributes»«ENDIF»''' // TODO
}

enum CardinalityType
{
	SINGLE,

	MULTIPLE
}

// TODO all references should be named "componentTypeSignature" or similar
@Data
class ComponentTypeSignature
{
	TypeReference typeReference

	Set<? extends QualifierModel> qualifiers

	def isAssignableFrom(ComponentTypeSignature otherComponentSignature)
	{
		typeReference.isAssignableFrom(otherComponentSignature.typeReference) &&
			otherComponentSignature.qualifiers.containsAll(qualifiers)
	}

	override toString()
	{
		asString.toString
	}

	def asString()
	'''«typeReference.name»/«qualifiers.map[asString]»'''
}

@Data
class ComponentReferenceSignature
{
	ComponentTypeSignature componentTypeSignature

	CardinalityType cardinality

	def boolean isAssignableFrom(ComponentReferenceSignature sourceComponentReferenceSignature)
	{
		val compatibleTypes = componentTypeSignature.isAssignableFrom(
			sourceComponentReferenceSignature.componentTypeSignature)

		val compatibleCardinalities = switch (cardinality)
		{
			case SINGLE:
				switch (sourceComponentReferenceSignature.cardinality)
				{
					case SINGLE: true
					case MULTIPLE: false
				}
			case MULTIPLE:
				true
		}

		return compatibleTypes && compatibleCardinalities
	}

	def List<? extends ComponentModel> resolve(StaticModuleModel moduleModel)
	{
		moduleModel.components.filter [ componentModel |
			componentTypeSignature.isAssignableFrom(componentModel.typeSignature)
		].toList.immutableCopy
	}
}

interface ComponentReference<T extends Declaration>
{
	def ComponentReferenceSignature getSignature()

	def ProviderType getProviderType()

	def boolean isOptional()

	def T getDeclaration()

	def TypeReference getTypeReference()

	def ResolvedComponentReference<T> resolve(StaticModuleModel moduleModel)
}

@Data
class ResolvedComponentReference<T extends Declaration>
{
	ComponentReference<T> componentReference

	List<? extends ComponentModel> resolvedComponents
}

@Data
class DeclaredComponentDependencyReference<T extends Declaration> implements ComponentReference<T>
{
	ComponentReferenceSignature signature

	ProviderType providerType

	boolean optional

	T declaration

	TypeReference typeReference

	@Cached
	override ResolvedComponentReference<T> resolve(StaticModuleModel moduleModel)
	{
		val resolvedComponents = signature.resolve(moduleModel)

		if (resolvedComponents.empty)
		{
			if (!optional)
			{
				throw new IocProcessingException(new ProcessingMessage(
					Severity.ERROR,
					declaration,
					'''Component reference resolution error, no compatible components found.'''
				))
			}
		}
		else if (signature.cardinality == CardinalityType.SINGLE && resolvedComponents.size > 1)
		{
			throw new IocProcessingException(
				new ProcessingMessage(
					Severity.
						ERROR,
					declaration,
					'''Component reference resolution error, multiple compatible components found: «resolvedComponents.map[it.getTypeSignature]»'''
				))
		}

		new ResolvedComponentReference(this, resolvedComponents)
	}
}

@Data
class ComponentReferenceToOwnerComponent<T extends Declaration> implements ComponentReference<T>
{
	ComponentModel ownerComponent

	T providerMethodDeclaration

	override getSignature()
	{
		new ComponentReferenceSignature(ownerComponent.typeSignature, CardinalityType.SINGLE)
	}

	override getProviderType()
	{
		ProviderType.DIRECT
	}

	override isOptional()
	{
		false
	}

	override getDeclaration()
	{
		providerMethodDeclaration
	}

	override getTypeReference()
	{
		ownerComponent.getTypeSignature.typeReference
	}

	@Cached
	override ResolvedComponentReference<T> resolve(StaticModuleModel moduleModel)
	{
		new ResolvedComponentReference(this, #[ownerComponent])
	}
}

@Data
abstract class ComponentModel implements HasPriority
{
	ComponentTypeSignature typeSignature

	ClassDeclaration lifecycleManagerClass

	int priority

	/**
	 * All component references.
	 */
	abstract def List<? extends ComponentReference<?>> getComponentReferences()
}

@Data
class ParameterizedQualifierModel
{
	String name

	Map<String, String> parameterNameToAttributeMap
}

@Data
class ComponentProviderModel extends ComponentModel
{
	// TODO rename: enclosingComponent
	ComponentClassModel ownerComponentModel

	MethodDeclaration providerMethodDeclaration

	Set<ParameterizedQualifierModel> parameterizedQualifiers

	override getComponentReferences()
	{
		#[new ComponentReferenceToOwnerComponent(ownerComponentModel, providerMethodDeclaration)]
	}

	def getParameterizedQualifierAttributeValue(String parameterName)
	{
		parameterizedQualifiers.filter[parameterNameToAttributeMap.containsKey(parameterName)].map [
			it -> parameterNameToAttributeMap.get(parameterName)
		].map [ parameterizedQualifierInfo |
			getTypeSignature.qualifiers.findFirst[name == parameterizedQualifierInfo.key.name].attributes.get(
				parameterizedQualifierInfo.value)
		].head
	}
}

@Data
class ComponentClassConstructorModel
{
	ConstructorDeclaration componentConstructor

	boolean constructorReceivesModuleInstance

	List<? extends ComponentReference<ParameterDeclaration>> injectedConstructorParameters
}

@Data
class ComponentSuperclassModel
{
	TypeReference typeReference

	ComponentSuperclassModel superclassModel

	List<? extends ComponentReference<? extends FieldDeclaration>> fieldComponentReferences

	List<? extends ComponentReference<? extends ParameterDeclaration>> constructorComponentReferences

	def private getDeclaredComponentReferences()
	{
		(fieldComponentReferences + constructorComponentReferences)
	}

	def Iterable<? extends ComponentReference<? extends Declaration>> getComponentReferences()
	{
		((if (superclassModel != null) superclassModel.componentReferences else #[]) + declaredComponentReferences).
			toList.immutableCopy
	}
}

@Data
class ComponentClassModel extends ComponentModel
{
	ClassDeclaration classDeclaration

	ComponentSuperclassModel superclassModel

	ConstructorDeclaration componentConstructor

	List<? extends ComponentReference<? extends FieldDeclaration>> fieldComponentReferences

	List<? extends ComponentReference<? extends ParameterDeclaration>> constructorComponentReferences

	List<? extends MethodDeclaration> postConstructMethods

	List<? extends MethodDeclaration> preDestroyMethods

	boolean eager

	def getDeclaredComponentReferences()
	{
		(fieldComponentReferences + constructorComponentReferences)
	}

	override List<? extends ComponentReference<?>> getComponentReferences()
	{
		((if (superclassModel != null) superclassModel.componentReferences else #[]) + declaredComponentReferences).
			toList.immutableCopy
	}

	def Iterable<ComponentReferenceSignature> getConstructorParameters()
	{
		componentReferences.groupBy[signature].keySet.immutableCopy // TODO ne feltétlenül signature szerint, lehetne esetleg komolyabb szűkítést?
	}
}

@Data
class StaticModuleModel
{
	InterfaceDeclaration moduleInterfaceDeclaration

	boolean nonAbstract // TODO isAbstract
	boolean singleton

	boolean gwtEntryPoint

	Set<? extends TypeReference> inheritedModules

	Set<? extends ComponentModel> components

	Set<? extends ComponentReference<MethodDeclaration>> explicitModuleDependencies

	/**
	 * Module resolution involves the resolution of all component references.
	 * 
	 * @throws IllegalStateException if the module is abstract
	 */
	def ResolvedModuleModel resolve()
	{
		if (!nonAbstract)
		{
			throw new IllegalStateException
		}

		val errorMessages = <ProcessingMessage>newArrayList()
		(explicitModuleDependencies + components.map[componentReferences].flatten).forEach [
			try
			{
				resolve(this)
			}
			catch (IocProcessingException e)
			{
				errorMessages += e.messages
			}
		]

		if (!errorMessages.empty)
		{
			throw new IocProcessingException(errorMessages)
		}

		// Generate component fields names
		val componentFieldNames = newHashMap
		components.forEach [ componentModel, index |
			componentFieldNames.put(componentModel, '''c«index»''')
		]

		return new ResolvedModuleModel(this, componentFieldNames)
	}
}

// TODO átalakítani, hogy @Data legyen, és kell egy másik külön class a plusz adatoknak, amire erre hivatkozik
@Data
class ResolvedModuleModel
{
	StaticModuleModel staticModuleModel

	// TODO nincs jó helyen
	Map<ComponentModel, String> componentSupplierFieldNames

	@Cached
	def DependencyGraph getDependencyGraph()
	{
		val allComponents = staticModuleModel.components

		val graph = new DependencyGraph(allComponents.map[new DependencyGraphNode(it)].toSet)

		val unprocessedComponents = newLinkedList
		unprocessedComponents.addAll(allComponents)

		while (!unprocessedComponents.empty)
		{
			val componentModel = unprocessedComponents.removeFirst
			val componentNode = graph.findNode(componentModel)

			componentModel.componentReferences.forEach [ componentReference |
				if (!componentReference.providerType.byProvider)
				{
					val compatibleComponents = componentReference.resolve(staticModuleModel)
					compatibleComponents.resolvedComponents.forEach [
						graph.addEdge(componentNode, graph.findNode(it))
					]
				}
			]
		}

		return graph
	}
}

@Data
class DependencyGraph
{
	val graph = new DirectedAcyclicGraph<DependencyGraphNode, DefaultEdge>(DefaultEdge)

	new(Set<DependencyGraphNode> nodes)
	{
		nodes.forEach[graph.addVertex(it)]
	}

	def DependencyGraphNode findNode(ComponentModel componentModel)
	{
		graph.vertexSet.findFirst[it.componentModel == componentModel]
	}

	def void addEdge(DependencyGraphNode from, DependencyGraphNode to)
	{
		try
		{
			graph.addEdge(from, to)
		}
		catch (Exception e)
		{
			val directedGraph = DefaultDirectedGraph.builder(DefaultEdge).addGraph(graph).build
			directedGraph.addEdge(from, to)

			val simpleCycles = new SzwarcfiterLauerSimpleCycles(directedGraph)
			val cycles = simpleCycles.findSimpleCycles

			throw new IocProcessingException(
				cycles.map [ cycle |
					new ProcessingMessage(
						Severity.
							ERROR,
						null,
						'''Component reference cycle detected: «(cycle.map[componentModel.typeSignature.typeReference.type.qualifiedName] + #[cycle.head.componentModel.typeSignature.typeReference.type.qualifiedName]).toList.join(" -> ")» [E004]'''
					)
				]
			)
		}
	}

	def nodes()
	{
		graph.iterator.toList.immutableCopy
	}

	override toString()
	{
		graph.toString
	}
}

@Data
class DependencyGraphNode
{
	ComponentModel componentModel

	override toString()
	{
		componentModel.getTypeSignature.typeReference.name
	}
}
