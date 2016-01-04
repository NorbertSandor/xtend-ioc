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
package com.erinors.ioc.examples.docs.injectmultiple

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
interface Handler {
}

@Component
class IntegerHandler implements Handler {
}

@Component
class DoubleHandler implements Handler {
}

@Component
class TestComponent {
	@Inject
	public List<? extends Handler> handlers // <1>
	@Inject
	public Iterable<Handler> handlers2 // <2>
}

@Module(components=#[IntegerHandler, DoubleHandler, TestComponent])
interface TestModule {
	def IntegerHandler integerHandler()

	def DoubleHandler doubleHandler()

	def TestComponent testComponent()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		assertEquals(
			#{module.doubleHandler, module.integerHandler},
			module.testComponent.handlers.toSet
		)
		assertEquals(
			module.testComponent.handlers,
			module.testComponent.handlers2
		)
	}
}
// end::Example[]
