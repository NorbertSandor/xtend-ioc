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
package com.erinors.ioc.examples.docs.prototype

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Prototype
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Component
@Prototype // <1>
class TestComponent {
}

@Module(components=TestComponent)
interface TestModule {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		val testComponent1 = module.testComponent
		val testComponent2 = module.testComponent
		assertTrue( // <2>
			testComponent1 != testComponent2
		)
	}
}
// end::Example[]
