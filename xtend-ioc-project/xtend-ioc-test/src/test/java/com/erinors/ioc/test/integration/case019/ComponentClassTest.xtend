/*
 * #%L
 * xtend-ioc-test
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.test.integration.case019

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Qualifier
import com.erinors.ioc.shared.impl.ModuleInstance
import org.junit.Test

import static org.junit.Assert.*

// Component class with default constructor and no component references 
@Component
class Component1
{
}

// Component class with declared no-args constructor but without component references 
@Component
class Component2
{
	@Inject
	new()
	{
	}
}

// Component class with default constructor and injected field 
@Component
class Component3
{
	@Inject
	public Component1 component1
}

// Component class with declared no-args constructor and injected field
@Component
class Component4
{
	@Inject
	public Component1 component1

	@Inject
	new()
	{
	}
}

// Component class with injected constructor
@Component
class Component5
{
	public Component1 component1

	@Inject
	new(Component1 component1)
	{
		this.component1 = component1
	}
}

// Component class with injected constructor and injected field
@Component
class Component6
{
	@Inject
	public Component1 component1

	public Component2 component2

	@Inject
	new(Component2 component2)
	{
		this.component2 = component2
	}
}

// As Component2 but the module instance is passed to the constructor
@Component
class Component2b
{
	@Inject
	new(ModuleInstance moduleInstance)
	{
	}
}

// As Component4 but the module instance is passed to the constructor
@Component
class Component4b
{
	@Inject
	public Component1 component1
	
	public ModuleInstance moduleInstance

	@Inject
	new(ModuleInstance moduleInstance)
	{
		this.moduleInstance = moduleInstance
	}
}

// As Component5 but the module instance is passed to the constructor
@Component
class Component5b1
{
	public Component1 component1

	@Inject
	new(ModuleInstance moduleInstance, Component1 component1)
	{
		this.component1 = component1
	}
}

// As Component5 but the module instance is passed to the constructor
@Component
class Component5b2
{
	public Component1 component1

	@Inject
	new(Component1 component1, ModuleInstance moduleInstance)
	{
		this.component1 = component1
	}
}

@Qualifier
annotation Component6bQualifier
{
}

// As Component6 but the module instance is passed to the constructor
@Component
@Component6bQualifier
class Component6b
{
	@Inject
	public Component1 component1

	public Component2 component2

	@Inject
	new(ModuleInstance moduleInstance, Component2 component2)
	{
		this.component2 = component2
	}
}

// Non-component
class NonComponent
{
}

// Component with non-component superclass
@Component
class ComponentWithNonComponentSuperclass extends NonComponent
{
}

// Component with component superclass
@Component
class ComponentWithComponentSuperclass extends Component6b
{
	@Inject
	public Component3 component3
}

@Module(components=#[Component1, Component2, Component3, Component4, Component5, Component6, Component2b, Component4b,
	Component5b1, Component5b2, Component6b, ComponentWithNonComponentSuperclass, ComponentWithComponentSuperclass])
interface TestModule
{
	def Component1 component1()

	def Component2 component2()

	def Component3 component3()

	def Component4 component4()

	def Component5 component5()

	def Component6 component6()

	def Component2b component2b()

	def Component4b component4b()

	def Component5b1 component5b1()

	def Component5b2 component5b2()

	@Component6bQualifier
	def Component6b component6b()

	def NonComponent nonComponent();

	def ComponentWithNonComponentSuperclass componentWithNonComponentSuperclass()

	def ComponentWithComponentSuperclass componentWithComponentSuperclass()
}

class ComponentClassTest
{
	@Test
	def void testInheritance()
	{
		val module = TestModule.Peer.initialize
		assertTrue(module.component3.component1 === module.component1)
		assertTrue(module.component4.component1 === module.component1)
		assertTrue(module.component5.component1 === module.component1)
		assertTrue(module.component6.component1 === module.component1)
		assertTrue(module.component6.component2 === module.component2)

		assertTrue(module.component4b.component1 === module.component1)
		assertTrue(module.component4b.moduleInstance === module)
		assertTrue(module.component5b1.component1 === module.component1)
		assertTrue(module.component5b2.component1 === module.component1)
		assertTrue(module.component6b.component1 === module.component1)
		assertTrue(module.component6b.component2 === module.component2)

		assertTrue(module.nonComponent === module.componentWithNonComponentSuperclass)

		assertTrue(module.component1 === module.componentWithComponentSuperclass.component1)
		assertTrue(module.component2 === module.componentWithComponentSuperclass.component2)
		assertTrue(module.component3 === module.componentWithComponentSuperclass.component3)
	}
}
