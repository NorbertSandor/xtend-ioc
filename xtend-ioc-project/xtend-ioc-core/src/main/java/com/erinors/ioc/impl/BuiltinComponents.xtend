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
import com.erinors.ioc.shared.api.InterceptorInvocationHandler
import com.erinors.ioc.shared.api.OrderConstants
import com.erinors.ioc.shared.api.PriorityConstants
import com.erinors.ioc.shared.impl.ModuleInstance
import com.erinors.ioc.shared.impl.SingletonComponentLifecycleManager
import java.util.Set
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.Data
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.services.Problem.Severity

class BuiltinComponentManagers
{
	def static BuiltinComponentManagers builtinComponentManagers(TransformationContext context)
	{
		new BuiltinComponentManagers(context)
	}

	@Accessors
	val Iterable<? extends ComponentManager> componentManagers

	private new(TransformationContext context)
	{
		componentManagers = #[new ModuleInstanceComponentManager(context), new EventComponentManager(context),
			new InterceptorHandlerComponentManager(context)]
	}
}

interface ComponentManager
{
	def void apply(ModuleModelBuilderContext context, ComponentClassModel componentModel)

	def void apply(ModuleModelBuilderContext context,
		Set<? extends DeclaredComponentReference<MethodDeclaration>> moduleComponentReferences)
}

abstract class AbstractComponentManager implements ComponentManager
{
	override apply(ModuleModelBuilderContext context, ComponentClassModel componentModel)
	{
		componentModel.componentReferences.forEach[apply(context, it)]
	}

	override apply(ModuleModelBuilderContext context,
		Set<? extends DeclaredComponentReference<MethodDeclaration>> moduleComponentReferences)
	{
		moduleComponentReferences.forEach[apply(context, it)]
	}

	def void apply(ModuleModelBuilderContext context, ComponentReference componentReference)
}

@FinalFieldsConstructor
class InterceptorHandlerComponentManager extends AbstractComponentManager
{
	val extension TransformationContext context

	override apply(ModuleModelBuilderContext context, ComponentReference componentReference)
	{
		if (InterceptorInvocationHandler.findTypeGlobally.isAssignableFrom(
			componentReference.signature.componentTypeSignature.typeReference.type) &&
			!context.exists(componentReference.signature.componentTypeSignature))
		{
			context.addComponentClass(componentReference.signature.componentTypeSignature.typeReference)
		}
	}
}

@Data
class ModuleInstanceComponentModel extends ComponentModel
{
	override getComponentReferences()
	{
		#[]
	}
}

@FinalFieldsConstructor
class ModuleInstanceComponentManager extends AbstractComponentManager
{
	val extension TransformationContext context

	override apply(ModuleModelBuilderContext context, ComponentReference componentReference)
	{
		// TODO ellenőrzés: components should not implement ModuleInstance
		if (ModuleInstance.newTypeReference.isAssignableFrom(
			componentReference.signature.componentTypeSignature.typeReference) &&
			!context.exists(componentReference.signature.componentTypeSignature))
		{
			context.addComponentModel(
				new ModuleInstanceComponentModel(componentReference.signature.componentTypeSignature,
					SingletonComponentLifecycleManager.findTypeGlobally as ClassDeclaration,
					PriorityConstants.MAX_PRIORITY, OrderConstants.DEFAULT_ORDER))
		}
	}
}

@Data
class EventComponentModel extends ComponentModel
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
class EventComponentManager extends AbstractComponentManager
{
	val extension TransformationContext context

	override apply(ModuleModelBuilderContext context, ComponentReference componentReference)
	{
		// TODO ne lehessen megadni scope-ot
		// TODO ne lehessen wildcard
		// TODO if the event exists with qualifiers then do not allow an event without qualifiers
		val signature = componentReference.signature
		if (Event.newTypeReference.isAssignableFrom(signature.componentTypeSignature.typeReference))
		{
			if (signature.cardinality != CardinalityType.SINGLE)
			{
				throw new IocProcessingException(
					new ProcessingMessage(Severity.ERROR, componentReference.
						compilationProblemTarget, '''Collections of «Event.simpleName»s is not supported.'''))
			}
			else if (componentReference.providerType != ProviderType.DIRECT)
			{
				throw new IocProcessingException(
					new ProcessingMessage(Severity.ERROR, componentReference.
						compilationProblemTarget, '''Indirect «Event.simpleName» reference is not supported.'''))
			}

			if (!context.exists(componentReference.signature.componentTypeSignature))
			{
				context.addComponentModel(
					new EventComponentModel(componentReference.signature.componentTypeSignature,
						SingletonComponentLifecycleManager.findTypeGlobally as ClassDeclaration,
						PriorityConstants.MAX_PRIORITY, OrderConstants.DEFAULT_ORDER))
			}
		}
	}
}
// TODO warning, ha Event típusú mező vagy constructor paraméter @Inject nélkül van
