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
package com.erinors.ioc.examples.docs.multiplemodules

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Provider
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Component // <1>
class TestComponent {
	@Inject
	public String value
}

@Component
class Provider1 {
	@Provider // <2>
	def String provider() '''1'''
}

@Component
class Provider2 {
	@Provider // <3>
	def String provider() '''2'''
}

@Module(components=#[TestComponent, Provider1]) // <4>
interface TestModule1 {
	def TestComponent testComponent()
}

@Module(components=#[TestComponent, Provider2]) // <5>
interface TestModule2 {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test() {
		val module1 = TestModule1.Peer.initialize
		val module2 = TestModule2.Peer.initialize
		val testComponent1 = module1.testComponent
		val testComponent2 = module2.testComponent
		assertEquals( // <6>
			"1", testComponent1.value
		)
		assertEquals( // <7>
			"2", testComponent2.value
		)
	}
}
// end::Example[]
