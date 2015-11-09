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

import com.erinors.ioc.impl.InjectableClassModelBuilder.ClassModel
import com.erinors.ioc.impl.InjectableClassModelBuilder.ComponentReferenceInjectionModel
import com.erinors.ioc.impl.InjectableClassModelBuilder.DeclaredInjectionModel
import com.erinors.ioc.impl.InjectableClassModelBuilder.NotInjectedConstructorParameterModel
import com.erinors.ioc.shared.api.Injectable
import com.google.common.base.Function
import com.google.common.base.Optional
import com.google.common.base.Supplier
import com.google.common.base.Suppliers
import com.google.common.collect.ImmutableList
import com.google.common.collect.Lists
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ConstructorDeclaration
import org.eclipse.xtend.lib.macro.declaration.Declaration
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.ParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.services.Problem.Severity

import static extension com.erinors.ioc.impl.IocUtils.*
import static extension com.erinors.ioc.impl.IterableUtils.*
import static extension com.erinors.ioc.impl.MapUtils.*

@FinalFieldsConstructor
package class InjectableClassModelBuilder
{
	@Data
	static abstract class DeclaredInjectionModel<T extends Declaration>
	{
		T declaration
	}

	@Data
	static class NotInjectedConstructorParameterModel extends DeclaredInjectionModel<ParameterDeclaration>
	{
	}

	@Data
	static class ComponentReferenceInjectionModel<T extends Declaration> extends DeclaredInjectionModel<T>
	{
		ComponentReference<?> componentReference

		ComponentReference<MethodDeclaration> sourceComponentReference
	}

	@Data
	static class ConstructorModel
	{
		ConstructorDeclaration constructorDeclaration

		Iterable<? extends DeclaredInjectionModel<? extends ParameterDeclaration>> parameters
	}

	@Data
	static class ClassModel
	{
		MutableClassDeclaration classDeclaration

		StaticModuleModel moduleModel

		Map<MutableFieldDeclaration, ? extends DeclaredInjectionModel<? extends FieldDeclaration>> injectedFields

		Iterable<? extends ConstructorModel> injectedConstructors
	}

	val extension TransformationContext context

	def private findCompatibleExplicitModuleDependency(StaticModuleModel moduleModel, Declaration declaration,
		TypeReference typeReference)
	{
		// TODO berendezni, hogy a "legközelebbit" adja eredményül (amihez a legkevesebb konverzió kell)
		val componentReference = moduleModel.explicitModuleDependencies.filter [ moduleComponentReference |
			createDependencyReference(declaration, typeReference, context).signature.isAssignableFrom(
				moduleComponentReference.signature)
		].head

		if (componentReference == null)
		{
			throw new IocProcessingException(
				new ProcessingMessage(
					Severity.
						ERROR,
					declaration,
					'''No compatible module-level dependency found. Add an explicit dependecy method to the module: «moduleModel.moduleInterfaceDeclaration.qualifiedName»'''
				))
		}

		return componentReference
	}

	def build(MutableClassDeclaration injectableClassDeclaration)
	{
		// Guaranteed by semantics: injectableClassDeclaration is annotated with @Injectable
		val moduleTypeReference = injectableClassDeclaration.findAnnotation(Injectable.findTypeGlobally).
			getClassValue("value")

		// Guaranteed by semantics: moduleTypeReference is assignable to ModuleImplementor
		val moduleInterfaceType = moduleTypeReference.type

		if (moduleInterfaceType instanceof InterfaceDeclaration)
		{
			val moduleModel = try
			{
				new ModuleModelBuilder(context).build(moduleInterfaceType)
			}
			catch (Exception e)
			{
				// Module is invalid, no references can be resolved.
				throw new CancelOperationException
			}

			// TODO check: events are not supported
			val injectedFields = injectableClassDeclaration.findInjectedFields(context).castElements(
				MutableFieldDeclaration).map [ injectedField |
				if (injectedField.initializer != null)
				{
					throw new IocProcessingException(new ProcessingMessage(
						Severity.ERROR,
						injectedField,
						'''@Inject-ed fields must not have an initializer.'''
					))
				}
				else
				{
					injectedField -> // FIXME component resolution csak akkor működik jól, ha a modul final! egyébként simán lehet, hogy egy leszármazott modul további komponenseket ad hozzá, amik módosítják a resolution eredményét.
//						if (moduleModel.isNonAbstract)
//						{
//							if (moduleModel.graphValid)
//							{
//								new ResolvedInjectionModel(injectedField,
//									createDependencyReference(injectedField, injectedField.type, context).resolve(
//										moduleModel))
//							}
//							else
//							{
//								new UnresolvedInjectionModel(injectedField)
//							}
//						}
//						else
//						{
					new ComponentReferenceInjectionModel(injectedField,
						createDependencyReference(injectedField, injectedField.type, context),
						findCompatibleExplicitModuleDependency(moduleModel, injectedField, injectedField.type))
//						}
				}
			].pairsToMap

			val injectedConstructors = injectableClassDeclaration.declaredConstructors.map [ constructor |
				if (constructor.isInjected(context))
				{
					if (constructor.parameters.empty)
					{
						throw new IocProcessingException(new ProcessingMessage(
							Severity.ERROR,
							constructor,
							'''@Inject is not allowed for no-args constructor (because it has no effect).'''
						))
					}
					else
					{
						buildConstructorModel(moduleModel, constructor, true)
					}
				}
				else
				{
					// FIXME check constructor collision
					if (constructor.parameters.exists[isInjected(context)])
					{
						buildConstructorModel(moduleModel, constructor, false)
					}
					else
					{
						null
					}
				}
			].filterNull

			return new ClassModel(injectableClassDeclaration, moduleModel, injectedFields, injectedConstructors)
		}
		else
		{
			throw new IocProcessingException(new ProcessingMessage(
				Severity.ERROR,
				injectableClassDeclaration,
				'''Invalid module interface reference, «moduleTypeReference» is not a module interface.'''
			))
		}
	}

	def buildConstructorModel(StaticModuleModel moduleModel, ConstructorDeclaration constructor,
		boolean allParametersAreInjected)
	{
		new ConstructorModel(constructor, constructor.parameters.map [ it |
			if (allParametersAreInjected || isInjected(context))
			{
				new ComponentReferenceInjectionModel(it, createDependencyReference(it, it.type, context),
					findCompatibleExplicitModuleDependency(moduleModel, it, it.type))
			}
			else
			{
				new NotInjectedConstructorParameterModel(it)
			}
		])
	}
}

@FinalFieldsConstructor
package class InjectableClassCodeGenerator
{
	val StaticModuleModel moduleModel

	val extension TransformationContext context

	def private static generateProviderConverter(ComponentReference<?> targetComponentReference,
		ComponentReference<?> sourceComponentReference, CharSequence sourceReferenceSourceCode,
		TransformationContext context)
		{
			switch (targetComponentReference.signature.cardinality)
			{
				case SINGLE:
					switch (sourceComponentReference.signature.cardinality)
					{
						case SINGLE:
							generateSingleProviderConverter(targetComponentReference, sourceComponentReference,
								sourceReferenceSourceCode, context)
						case MULTIPLE:
							generateSingleProviderConverter(targetComponentReference,
								sourceComponentReference, '''«sourceReferenceSourceCode».iterator().next()''',
								context)
						}
					case MULTIPLE:
						switch (sourceComponentReference.signature.cardinality)
						{
							case SINGLE:
							'''(«List.name»)«ImmutableList.name».of(«generateSingleProviderConverter(targetComponentReference, sourceComponentReference, sourceReferenceSourceCode, context)»)'''
							case MULTIPLE:
								if (targetComponentReference.providerType == sourceComponentReference.providerType)
								'''(«List.name»)«sourceReferenceSourceCode»'''
								else
									generateMultipleProviderConverter(targetComponentReference,
										sourceComponentReference, '''«sourceReferenceSourceCode»''', context)
						}
				}
			}

			def private static generateSingleProviderConverter(ComponentReference<?> targetComponentReference,
				ComponentReference<?> sourceComponentReference, CharSequence sourceReferenceSourceCode,
				TransformationContext context)
			{
				switch (targetComponentReference.providerType)
				{
					case DIRECT:
						switch (sourceComponentReference.providerType)
						{
							case DIRECT:
								sourceReferenceSourceCode
							case GUAVA_OPTIONAL:
							'''((«targetComponentReference.signature.componentTypeSignature.typeReference.name»)((«sourceReferenceSourceCode»).orNull()))'''
							case GUAVA_SUPPLIER:
							'''((«targetComponentReference.signature.componentTypeSignature.typeReference.name»)((«sourceReferenceSourceCode»).get()))'''
						}
					case GUAVA_OPTIONAL:
						switch (sourceComponentReference.providerType)
						{
							case DIRECT:
							'''(«Optional.name»)«Optional.name».of(«sourceReferenceSourceCode»)'''
							case GUAVA_OPTIONAL:
							'''(«Optional.name»)«sourceReferenceSourceCode»''' // TODO type
							case GUAVA_SUPPLIER:
							'''((«Optional.name»)«Optional.name».fromNullable(«sourceReferenceSourceCode».get()))'''
						}
					case GUAVA_SUPPLIER:
						switch (sourceComponentReference.providerType)
						{
							case DIRECT:
							'''(«Supplier.name»)«Suppliers.name».ofInstance(«sourceReferenceSourceCode»)'''
							case GUAVA_OPTIONAL: // TODO rendes típusokkal
							'''new «Supplier.name»() {
							public Object get() {
								return «sourceReferenceSourceCode».orNull();
							}
						}'''
							case GUAVA_SUPPLIER:
							'''(«Supplier.name»)«sourceReferenceSourceCode»''' // TODO type
						}
				}
			}

			def private static generateMultipleProviderConverter(
				ComponentReference<?> targetComponentReference,
				ComponentReference<?> sourceComponentReference,
				CharSequence sourceReferenceSourceCode,
				TransformationContext context
			)
			'''(«List.name»)«ImmutableList.name».copyOf(«Lists.name».transform(«sourceReferenceSourceCode», new «Function.name»<«IocUtils.getProviderTypeReference(sourceComponentReference, context).name», «IocUtils.getProviderTypeReference(targetComponentReference, context).name»>() {
						public «IocUtils.getProviderTypeReference(targetComponentReference, context).name» apply(final «IocUtils.getProviderTypeReference(sourceComponentReference, context).name» e) {
							return «generateSingleProviderConverter(targetComponentReference, sourceComponentReference, "e", context)»;
						}
			}))'''

			def private generateModuleMethodCall(
				InterfaceDeclaration moduleInterfaceDeclaration,
				ComponentReference<?> componentReference,
				ComponentReference<MethodDeclaration> sourceComponentReference
			)
			{
				if (componentReference != null)
					generateProviderConverter(componentReference,
						sourceComponentReference, '''«moduleInterfaceDeclaration.qualifiedName».Peer.get().«sourceComponentReference.declaration.simpleName»()''',
						context)
					else
						"null"
				}

				def private CharSequence toSourceCode(DeclaredInjectionModel<?> declaredInjectionModel) // TODO rename
				{
					switch (declaredInjectionModel)
					{
						NotInjectedConstructorParameterModel:
							declaredInjectionModel.declaration.simpleName
						ComponentReferenceInjectionModel<?>:
							generateModuleMethodCall(
								moduleModel.moduleInterfaceDeclaration,
								declaredInjectionModel.componentReference,
								declaredInjectionModel.sourceComponentReference
							)
					}
				}

				def generate(ClassModel classModel)
				{
					classModel.injectedFields.forEach [ injectedField, declaredInjectionModel |
						injectedField.final = true
						injectedField.initializer = '''«declaredInjectionModel.toSourceCode»'''
					]

					classModel.injectedConstructors.forEach [ injectedConstructor |
						classModel.classDeclaration.addConstructor [ newConstructor |

							injectedConstructor.parameters.
								forEach [
									if (it instanceof NotInjectedConstructorParameterModel)
									{
										newConstructor.addParameter(declaration.simpleName, declaration.type)
									}
								]

							newConstructor.body = '''
								this(«FOR parameter : injectedConstructor.parameters SEPARATOR ", "»«parameter.toSourceCode»«ENDFOR»);
							'''
						]
					]
				}
			}

			class InjectableProcessor extends AbstractSafeClassProcessor
			{
				new()
				{
					super(new InjectableProcessorImplementation, Injectable, "E003")
				}
			}

			class InjectableProcessorImplementation extends AbstractClassProcessor
			{
				override doTransform(MutableClassDeclaration annotatedClass, extension TransformationContext context)
				{
					try
					{
						val classModel = new InjectableClassModelBuilder(context).build(annotatedClass)
						new InjectableClassCodeGenerator(classModel.moduleModel, context).generate(classModel)
					}
					catch (Exception e)
					{
						ProcessorUtils.handleExceptions(e, context, annotatedClass)
					}
				}
			}

