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
import org.eclipse.xtend.lib.macro.services.TypeReferenceProvider
import static extension com.erinors.ioc.impl.MapUtils.*
import org.eclipse.xtend.lib.macro.declaration.AnnotationTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.Element
import de.oehme.xtend.contrib.Buildable

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
	'''«typeReference.name»«IF !qualifiers.empty»/«qualifiers.map[asString]»«ENDIF»'''
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

interface ComponentReference
{
	def ComponentReferenceSignature getSignature()

	def ProviderType getProviderType()

	def Element getCompilationProblemTarget()

	def TypeReference getTypeReference()

	def ResolvedComponentReference resolve(StaticModuleModel moduleModel)
}

@Data
class ResolvedComponentReference
{
	ComponentReference componentReference

	List<? extends ComponentModel> resolvedComponents
}

@Data
abstract class AbstractComponentDependencyReference implements ComponentReference
{
	ComponentReferenceSignature signature

	ProviderType providerType

	boolean optional

	@Cached
	override ResolvedComponentReference resolve(StaticModuleModel moduleModel)
	{
		val resolvedComponents = signature.resolve(moduleModel)

		if (resolvedComponents.empty)
		{
			if (!optional)
			{
				throw new IocProcessingException(new ProcessingMessage(
					Severity.ERROR,
					compilationProblemTarget,
					'''
						Component reference resolution error in module: «moduleModel»
						No component is compatible with: «signature.componentTypeSignature»
						[E006]
					'''
				))
			}
		}
		else if (signature.cardinality == CardinalityType.SINGLE && resolvedComponents.size > 1)
		{
			throw new IocProcessingException(new ProcessingMessage(
				Severity.ERROR,
				compilationProblemTarget,
				'''
					Component reference resolution error in module: «moduleModel»
					Multiple components are compatible with «signature.componentTypeSignature» but expected only one. 
					Compatible components: «resolvedComponents»
					[E007]
				''' // TODO test if the output is readable
			))
		}

		new ResolvedComponentReference(this, resolvedComponents)
	}
}

@Accessors
class GeneratedComponentReference extends AbstractComponentDependencyReference
{
	val Element compilationProblemTarget

	new(TypeReference targetTypeReference, Element compilationProblemTarget)
	{
		super(new ComponentReferenceSignature(new ComponentTypeSignature(targetTypeReference, #{}),
			CardinalityType.SINGLE), ProviderType.DIRECT, false)
		this.compilationProblemTarget = compilationProblemTarget
	}

	override getTypeReference()
	{
		signature.componentTypeSignature.typeReference
	}
}

@Data
class DeclaredComponentReference<T extends Declaration> extends AbstractComponentDependencyReference
{
	T declaration

	TypeReference declaredTypeReference

	override getCompilationProblemTarget()
	{
		declaration
	}

	override getTypeReference()
	{
		declaredTypeReference
	}
}

@Data
class ComponentReferenceToOwnerComponent implements ComponentReference
{
	ComponentModel ownerComponent

	MethodDeclaration providerMethodDeclaration

	override getSignature()
	{
		new ComponentReferenceSignature(ownerComponent.typeSignature, CardinalityType.SINGLE)
	}

	override getProviderType()
	{
		ProviderType.DIRECT
	}

	override getCompilationProblemTarget()
	{
		providerMethodDeclaration
	}

	override getTypeReference()
	{
		ownerComponent.getTypeSignature.typeReference
	}

	@Cached
	override ResolvedComponentReference resolve(StaticModuleModel moduleModel)
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
	abstract def List<? extends ComponentReference> getComponentReferences()
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
	ComponentClassModel enclosingComponentModel

	MethodDeclaration providerMethodDeclaration

	Set<ParameterizedQualifierModel> parameterizedQualifiers

	override getComponentReferences()
	{
		#[new ComponentReferenceToOwnerComponent(enclosingComponentModel, providerMethodDeclaration)]
	}

	def getParameterizedQualifierAttributeValue(String parameterName)
	{
		parameterizedQualifiers.filter[parameterNameToAttributeMap.containsKey(parameterName)].map [
			it -> parameterNameToAttributeMap.get(parameterName)
		].map [ parameterizedQualifierModel |
			val qualifierModel = typeSignature.qualifiers.findFirst[name == parameterizedQualifierModel.key.name]
			if (qualifierModel ===
				null)
			{
				throw new IllegalStateException('''«typeSignature», «parameterizedQualifierModel», «enclosingComponentModel», «providerMethodDeclaration.simpleName»''')
			}
			qualifierModel.attributes.get(parameterizedQualifierModel.value)
		].head
	}
}

@Data
class ComponentClassConstructorModel
{
	ConstructorDeclaration componentConstructor

	boolean constructorReceivesModuleInstance

	List<? extends DeclaredComponentReference<ParameterDeclaration>> injectedConstructorParameters
}

// TODO handle common fields with ComponentClassModel
@Data
class ComponentSuperclassModel
{
	TypeReference typeReference

	ComponentSuperclassModel superclassModel

	List<? extends DeclaredComponentReference<? extends FieldDeclaration>> fieldComponentReferences

	List<? extends DeclaredComponentReference<? extends ParameterDeclaration>> constructorComponentReferences

	List<? extends GeneratedComponentReference> generatedComponentReferences

	List<? extends InterceptedMethod> interceptedMethods

	def private getDeclaredComponentReferences()
	{
		(fieldComponentReferences + constructorComponentReferences + generatedComponentReferences)
	}

	def Iterable<? extends ComponentReference> getComponentReferences()
	{
		((if (superclassModel !== null) superclassModel.componentReferences else #[]) + declaredComponentReferences).
			toList.immutableCopy
	}
}

@Data
class ComponentClassModel extends ComponentModel
{
	ClassDeclaration classDeclaration

	ComponentSuperclassModel superclassModel

	ConstructorDeclaration componentConstructor

	List<? extends DeclaredComponentReference<? extends FieldDeclaration>> fieldComponentReferences

	List<? extends DeclaredComponentReference<? extends ParameterDeclaration>> constructorComponentReferences

	List<? extends GeneratedComponentReference> generatedComponentReferences

	List<? extends MethodDeclaration> postConstructMethods

	List<? extends MethodDeclaration> preDestroyMethods

	boolean eager

	List<? extends InterceptedMethod> interceptedMethods

	def getDeclaredComponentReferences()
	{
		(fieldComponentReferences + constructorComponentReferences + generatedComponentReferences)
	}

	override List<? extends ComponentReference> getComponentReferences()
	{
		((if (superclassModel !== null) superclassModel.componentReferences else #[]) + declaredComponentReferences).
			toList.immutableCopy
	}

	def Iterable<ComponentReferenceSignature> getConstructorParameters()
	{
		componentReferences.groupBy[signature].keySet.immutableCopy // TODO ne feltétlenül signature szerint, lehetne esetleg komolyabb szűkítést?
	}

	def String getGeneratedComponentReferenceFieldName(GeneratedComponentReference generatedComponentReference)
	{
		if (!generatedComponentReferences.contains(generatedComponentReference))
		{
			throw new IllegalArgumentException('''Not a generated component reference: «generatedComponentReference»''')
		}

		// TODO use random name
		return '''_generated_«generatedComponentReferences.indexOf(generatedComponentReference)»'''
	}
}

interface ModuleModel {
	def StaticModuleModel getStaticModuleModel()
}

@Data
class StaticModuleModel implements ModuleModel
{
	InterfaceDeclaration moduleInterfaceDeclaration

	boolean isAbstract

	boolean singleton

	Set<? extends TypeReference> inheritedModules

	Set<? extends ComponentModel> components

	Set<? extends DeclaredComponentReference<MethodDeclaration>> explicitModuleDependencies

	/**
	 * Module resolution involves the resolution of all component references.
	 * 
	 * @throws IllegalStateException if the module is abstract
	 */
	def ResolvedModuleModel resolve()
	{
		if (abstract)
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

	override toString()
	'''«moduleInterfaceDeclaration.qualifiedName»'''
	
	override getStaticModuleModel() {
		this
	}
}

@Data
class ResolvedModuleModel implements ModuleModel
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

interface InterceptorParameterType
{
	def TypeReference getApiType(TypeReferenceProvider typeReferenceProvider)
}

@Data
class BasicInterceptorParameterType implements InterceptorParameterType
{
	TypeReference typeReference

	override getApiType(TypeReferenceProvider typeReferenceProvider)
	{
		typeReference
	}
}

@Data
class MethodReferenceInterceptorParameterType implements InterceptorParameterType
{
	TypeReference returnType

	Iterable<TypeReference> parameterTypes

	override getApiType(extension TypeReferenceProvider typeReferenceProvider)
	{
		switch (parameterTypes.length)
		{
			case 0:
				Functions.Function0.newTypeReference(returnType)
			case 1:
				Functions.Function1.newTypeReference(parameterTypes.get(0), returnType)
			case 2:
				Functions.Function2.newTypeReference(parameterTypes.get(0), parameterTypes.get(1), returnType)
			case 3:
				Functions.Function3.newTypeReference(parameterTypes.get(0), parameterTypes.get(1),
					parameterTypes.get(2), returnType)
			case 4:
				Functions.Function4.newTypeReference(parameterTypes.get(0), parameterTypes.get(1),
					parameterTypes.get(2), parameterTypes.get(3), returnType)
			case 5:
				Functions.Function5.newTypeReference(parameterTypes.get(0), parameterTypes.get(1),
					parameterTypes.get(2), parameterTypes.get(3), parameterTypes.get(4), returnType)
			case 6:
				Functions.Function6.newTypeReference(parameterTypes.get(0), parameterTypes.get(1),
					parameterTypes.get(2), parameterTypes.get(3), parameterTypes.get(4), parameterTypes.get(5),
					returnType)
				default:
					throw new IllegalStateException // FIXME
			}
		}
	}

	@Data
	class InterceptorParameterModel<T extends InterceptorParameterType>
	{
		String name

		T type
	}

	@Data
	class InterceptorDefinitionModel
	{
		AnnotationTypeDeclaration interceptorAnnotation

		String invocationPointConfigurationClassName

		List<? extends InterceptorParameterModel<?>> parameters
	}

	@Data
	abstract class InterceptorArgumentModel<T extends InterceptorParameterType>
	{
		T parameter

		def abstract CharSequence generateSourceCode(TypeReferenceProvider typeReferenceProvider)
	}

	@Data
	class BasicInterceptorArgument extends InterceptorArgumentModel<BasicInterceptorParameterType>
	{
		Object value

		override generateSourceCode(TypeReferenceProvider typeReferenceProvider)
		{
			ProcessorUtils.valueToSourceCode(value)
		}
	}

	@Data
	class MethodReferenceInterceptorArgument extends InterceptorArgumentModel<MethodReferenceInterceptorParameterType>
	{
		String methodName

		// FIXME more correct implementation
		override generateSourceCode(extension TypeReferenceProvider typeReferenceProvider)
		{
			val parameterCount = parameter.parameterTypes.length
			val functionTypeReference = switch (parameterCount)
			{
				case 0:
					Functions.Function0
				case 1:
					Functions.Function1
				case 2:
					Functions.Function2
				case 3:
					Functions.Function3
				case 4:
					Functions.Function4
				case 5:
					Functions.Function5
				case 6:
					Functions.Function6
			}.newTypeReference(parameter.parameterTypes + #[parameter.returnType])

			val functionParameters = parameter.parameterTypes.indexed.map['''p«key»''' -> value].
				pairsToMap

			// TODO typeReference source name
			'''
				new «functionTypeReference.name.replace('$', '.')»() {
					public «parameter.returnType.wrapperIfPrimitive» apply(«FOR functionParameter : functionParameters.entrySet SEPARATOR ", "»«functionParameter.value.wrapperIfPrimitive.name» «functionParameter.key»«ENDFOR») {
						«IF !parameter.returnType.void»return «ENDIF»«methodName»(«FOR functionParameter : functionParameters.entrySet SEPARATOR ", "»«functionParameter.key»«ENDFOR»);
						«IF parameter.returnType.void»return null;«ENDIF»
					}
				}
			'''
		}
	}

	@Data
	class InterceptorInvocationModel
	{
		InterceptorDefinitionModel definitionModel

		GeneratedComponentReference invocationHandlerReference

		List<? extends InterceptorArgumentModel<?>> arguments
	}

	@Data
	class InterceptedMethod
	{
		MethodDeclaration methodDeclaration

		List<? extends InterceptorInvocationModel> interceptorInvocations
	}

	