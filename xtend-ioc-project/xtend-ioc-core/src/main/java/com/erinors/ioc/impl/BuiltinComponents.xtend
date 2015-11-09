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
import com.erinors.ioc.shared.api.Event
import com.erinors.ioc.shared.api.PriorityConstants
import com.erinors.ioc.shared.impl.ModuleInstance
import com.erinors.ioc.shared.impl.SingletonComponentLifecycleManager
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.services.Problem.Severity

class BuiltinComponentManagers
{
	def static BuiltinComponentManagers builtinComponentManagers(TransformationContext context)
	{
		new BuiltinComponentManagers(context)
	}

	val Iterable<? extends ComponentManager> componentManagers

	private new(TransformationContext context)
	{
		componentManagers = #[new ModuleInstanceComponentManager(context), new EventComponentManager(context)]
	}

	def findFor(ModuleModelBuilderContext context, ComponentReference<?> componentReference)
	{
		val filteredComponentManagers = componentManagers.filter[supports(context, componentReference)]
		switch (filteredComponentManagers.size)
		{
			case 0:
				null
			case 1:
				filteredComponentManagers.
					head
			default:
				throw new IllegalStateException('''Multiple component managers found for «componentReference»: «filteredComponentManagers»''')
		}
	}

}

interface ComponentManager
{
	def boolean supports(ModuleModelBuilderContext context, ComponentReference<?> componentReference)

	def void processComponentReference(ModuleModelBuilderContext context, ComponentClassModel componentModel,
		ComponentReference<?> reference)
}

@Data
abstract class BuiltinComponentModel extends ComponentModel
{
}

@Data
class ModuleInstanceComponentModel extends BuiltinComponentModel
{
	override getComponentReferences()
	{
		#[]
	}
}

@FinalFieldsConstructor
class ModuleInstanceComponentManager implements ComponentManager
{
	val extension TransformationContext context

	override supports(ModuleModelBuilderContext context, ComponentReference<?> componentReference)
	{
		ModuleInstance.newTypeReference.isAssignableFrom(
			componentReference.signature.componentTypeSignature.typeReference)
	}

	override processComponentReference(ModuleModelBuilderContext context, ComponentClassModel componentModel,
		ComponentReference<?> reference)
	{
		// TODO ellenőrzés: components should not implement ModuleInstance
		if (!context.exists(reference.signature.componentTypeSignature))
		{
			context.addComponentModel(
				new ModuleInstanceComponentModel(reference.signature.componentTypeSignature,
					SingletonComponentLifecycleManager.findTypeGlobally as ClassDeclaration,
					PriorityConstants.MAX_PRIORITY))
			}
		}
	}

	@Data
	class EventComponentModel extends BuiltinComponentModel
	{
		override getComponentReferences()
		{
			#[]
		}

		def getEventTypeReference()
		{
			typeSignature.typeReference.actualTypeArguments.get(0)
		}
	}

	@FinalFieldsConstructor
	class EventComponentManager implements ComponentManager
	{
		val extension TransformationContext context

		override supports(ModuleModelBuilderContext context, ComponentReference<?> componentReference)
		{
			// TODO ne lehessen megadni scope-ot
			// TODO ne lehessen wildcard
			val signature = componentReference.signature
			if (Event.newTypeReference.isAssignableFrom(signature.componentTypeSignature.typeReference))
			{
				if (signature.cardinality != CardinalityType.SINGLE)
				{
					throw new IocProcessingException(
						new ProcessingMessage(Severity.ERROR,
							componentReference.declaration, '''Collections of «Event.simpleName»s is not supported.'''))
				}
				else if (componentReference.providerType != ProviderType.DIRECT)
				{
					throw new IocProcessingException(
						new ProcessingMessage(Severity.ERROR, componentReference.
							declaration, '''Indirect «Event.simpleName» reference is not supported.'''))
				}
				else
				{
					true
				}
			}
			else
			{
				false
			}
		}

		override processComponentReference(ModuleModelBuilderContext context, ComponentClassModel componentModel,
			ComponentReference<?> reference)
		{
			if (!context.exists(reference.signature.componentTypeSignature))
			{
				context.addComponentModel(
					new EventComponentModel(reference.signature.componentTypeSignature,
						SingletonComponentLifecycleManager.findTypeGlobally as ClassDeclaration,
						PriorityConstants.MAX_PRIORITY))
				}
			}
		}
// TODO warning, ha Event típusú mező vagy constructor paraméter @Inject nélkül van
