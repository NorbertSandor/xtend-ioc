/*
 * #%L
 * xtend-ioc-examples
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.examples.docs.moduleinheritance2

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Component
class TestComponent {
}

@Module(components=TestComponent)
interface ParentModule {
	def TestComponent testComponent()
}

@Module // <1>
interface TestModule extends ParentModule {
}

class Example {
	@Test
	def void test() {
		TestModule.Peer.initialize // <2>
		assertTrue(TestModule.Peer.get === ParentModule.Peer.get) // <3>
		assertTrue( // <4>
			TestModule.Peer.get.testComponent ===
			ParentModule.Peer.get.testComponent
		)
	}
}
// end::Example[]
