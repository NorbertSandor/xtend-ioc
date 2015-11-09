/*
 * #%L
 * xtend-ioc-examples
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.examples.docs.avoiddependencygraphcycle

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Supplier
import org.junit.Test

import static org.junit.Assert.*

//
// Note this file and /xtend-ioc-core/src/test/java/com/erinors/ioc/impl/CycleDetectionTest.xtend should stay in sync!
//

// tag::Example[]
@Component
class Component1 {
	// Direct injection is not allowed because it would cause two cycles in the dependency graph.
	// @Inject
	// Component4 component4
	
	@Inject // <1>
	Supplier<Component4> component4Supplier

	def boolean someBusinessMethod() {
		!component4Supplier.get.anotherBusinessMethod // <2>
	}
}

@Component
class Component2 {
	@Inject
	public Component1 component1
}

@Component
class Component3 {
	@Inject
	public Component1 component1

	@Inject
	public Component2 component2
}

@Component
class Component4 {
	@Inject
	public Component3 component3

	def anotherBusinessMethod() {
		true
	}
}

@Module(components=#[Component1, Component2, Component3, Component4])
interface TestModule
{
	def Component1 component1()
}

class AvoidDependencyGraphCycleTest {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		assertFalse(module.component1.someBusinessMethod)
	}
}
// end::Example[]
