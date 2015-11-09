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
package com.erinors.ioc.examples.docs.componentscan

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
interface SomeInterface {
}

@Component
class Component1 implements SomeInterface {
}

@Component
class Component2 implements SomeInterface {
}

@Module(componentScanClasses=TestModule) // <1>
interface TestModule {
	def List<SomeInterface> instances()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		assertEquals(2, module.instances.size) // <2>
	}
}
// end::Example[]
