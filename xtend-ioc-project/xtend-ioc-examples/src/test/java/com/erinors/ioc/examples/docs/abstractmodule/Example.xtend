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
package com.erinors.ioc.examples.docs.abstractmodule

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test
import com.erinors.ioc.shared.api.Inject

// tag::Example[]
interface SomeService {
}

@Component
class TestComponent {
	@Inject
	public SomeService someService
}

@Module(components=TestComponent, isAbstract=true) // <1>
interface ParentModule {
	def TestComponent testComponent()
}

@Component
class SomeServiceComponent implements SomeService {
}

@Module(components=SomeServiceComponent)
interface TestModule extends ParentModule {
	def SomeService someService()
}

class Example {
	@Test
	def void test() {
		// Compile-time error: ParentModule.Peer.initialize() <2>
		val module = TestModule.Peer.initialize
		assertTrue(TestModule.Peer.get === ParentModule.Peer.get) // <3>
		assertTrue(module.testComponent.someService === module.someService) // <4>
	}
}
// end::Example[]
