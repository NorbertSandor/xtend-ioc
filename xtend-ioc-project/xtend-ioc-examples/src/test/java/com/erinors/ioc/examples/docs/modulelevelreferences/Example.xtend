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
package com.erinors.ioc.examples.docs.modulelevelreferences

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Supplier
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
interface SomeInterface {
}

@Component
class TestComponent implements SomeInterface {
}

@Module(components=TestComponent)
interface TestModule { // <1>
	def TestComponent testComponent()

	def SomeInterface someInterface()

	def Supplier<SomeInterface> someInterfaceSupplier()
}

class Example {
	@Test
	def void test() { // <2>
		val module = TestModule.Peer.initialize
		assertTrue(module.testComponent === module.someInterface)
		assertTrue(module.testComponent === module.someInterfaceSupplier.get)
	}
}
// end::Example[]
