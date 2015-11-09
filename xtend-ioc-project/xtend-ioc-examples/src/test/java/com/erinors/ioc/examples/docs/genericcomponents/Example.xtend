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
package com.erinors.ioc.examples.docs.genericcomponents

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import java.util.List
import static org.junit.Assert.*
import org.junit.Test

// tag::Example[]
interface Handler<T> {
}

@Component
class IntegerHandler implements Handler<Integer> {
}

@Component
class DoubleHandler implements Handler<Double> {
}

@Component
class TestComponent {
	@Inject
	public Handler<Integer> integerHandler

	@Inject
	public List<Handler<? extends Number>> numberHandlers // <1>
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
		assertTrue(module.integerHandler == module.testComponent.integerHandler)
		assertTrue(
			#{module.doubleHandler, module.integerHandler} == module.testComponent.numberHandlers.toSet
		)
	}
}
// end::Example[]
