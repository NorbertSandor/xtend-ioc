/*
 * #%L
 * xtend-ioc-test
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.test.integration.case018

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.test.integration.HelloService
import com.erinors.ioc.test.integration.HelloServiceImpl
import org.junit.Test

import static org.junit.Assert.*

@Component
abstract class ParentWithInjectedField
{
	@Inject
	public HelloService injectedByField
}

@Component
abstract class ParentWithInjectedConstructor
{
	public HelloService injectedByConstructor
	
	@Inject
	new (HelloService helloService)
	{
		injectedByConstructor = helloService
	}
}

@Component
class Child1 extends ParentWithInjectedField
{
}

@Component
class Child2 extends ParentWithInjectedConstructor
{
	// FIXME validálni! ha van declared konstruktora, akkor biztosan nem adja át a modult az ősnek! pl. @EventObserver ilyenkor nem működik az ősben!
	// Ezen lehet kicsit reszelni azzal, ha támogatjuk az explicit ModuleImplementor-os konstruktort is.
	
	@Inject
	new (HelloService helloService)
	{
		super(helloService)
	}
}

@Module(components=#[HelloServiceImpl, Child1, Child2])
interface TestModule
{
	def Child1 child1()

	def Child2 child2()
}

class ComponentInheritanceTest
{
	@Test
	def void testComponentInheritance()
	{
		val module = TestModule.Peer.initialize
		assertNotNull(module.child1.injectedByField)
		assertNotNull(module.child2.injectedByConstructor)
	}
}
