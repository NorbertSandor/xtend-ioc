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
package com.erinors.ioc.shared.impl

import com.erinors.ioc.shared.api.ComponentLifecycleManager
import com.erinors.ioc.shared.api.SupportsPredestroyCallbacks
import com.google.common.base.Supplier
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

// TODO nem létező típus kezelése pl. module öröklődésnél
// TODO @Provider-t lehessen field-re is tenni
// TODO predesotry, postconstruct metódusok lehessenek private-ek


interface ModuleInstance
{
}

interface ComponentReferenceSupplier<T> extends Supplier<T>
{
	def boolean isPresent()
}

class AbsentComponentReferenceSupplier<T> implements ComponentReferenceSupplier<T>
{
	val static INSTANCE = new AbsentComponentReferenceSupplier

	def static <T> AbsentComponentReferenceSupplier<T> of()
	{
		INSTANCE as AbsentComponentReferenceSupplier
	}

	private new()
	{
	}

	override isPresent()
	{
		false
	}

	override get()
	{
		null
	}
}

@FinalFieldsConstructor
class PresentComponentReferenceSupplier<T> implements ComponentReferenceSupplier<T>
{
	val Supplier<T> supplier
	
	override isPresent()
	{
		true
	}

	override get()
	{
		supplier.get
	}
}

interface ModuleImplementor extends ModuleInstance
{
	def void close()

	// TODO this should not be publicly available
	def String getModuleInitializerInfo()

	def ModuleEventBus getModuleEventBus()
}

abstract class AbstractModuleImplementor implements ModuleImplementor
{
	@Accessors
	val ModuleEventBus moduleEventBus = new ModuleEventBusImpl

	@Accessors
	val String moduleInitializerInfo

	protected new(String moduleInitializerInfo)
	{
		this.moduleInitializerInfo = moduleInitializerInfo
	}
}

abstract class AbstractComponentLifecycleManager<T> implements ComponentLifecycleManager<T>
{
	protected def T createInstance()
}

@SupportsPredestroyCallbacks
abstract class SingletonComponentLifecycleManager<T> extends AbstractComponentLifecycleManager<T>
{
	enum State
	{
		UNINITIALIZED,
		INITIALIZING,
		READY
	}

	State state = State.UNINITIALIZED

	T instance

	override get()
	{
		switch (state)
		{
			case UNINITIALIZED:
			{
				state = State.INITIALIZING
				instance = createInstance
				state = State.READY
			}
			case INITIALIZING:
			{
				throw new IllegalStateException('''Recursion detected during component initialization.''')
			}
			case READY:
			{
			}
		}

		return instance
	}
}

abstract class PrototypeComponentLifecycleManager<T> extends AbstractComponentLifecycleManager<T>
{
	override get()
	{
		createInstance
	}
}
