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
package com.erinors.ioc.examples.docs.supplier

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Supplier
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
interface Handler<T> {}

@Component
class AnotherComponent {
}

@Component
class TestComponent {
	@Inject // <1>
	public Supplier<AnotherComponent> componentSupplier

	@Inject
	public AnotherComponent injectedComponent
}

@Module(components=#[AnotherComponent, TestComponent])
interface TestModule {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test()	{
		val module = TestModule.Peer.initialize
		val testComponent = module.testComponent
		assertTrue( // <2>
			testComponent.injectedComponent == testComponent.componentSupplier.get
		)
	}
}
// end::Example[]
