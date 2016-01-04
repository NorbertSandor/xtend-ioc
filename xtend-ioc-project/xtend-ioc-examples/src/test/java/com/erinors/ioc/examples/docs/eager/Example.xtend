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
package com.erinors.ioc.examples.docs.eager

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Eager
import com.erinors.ioc.shared.api.Module
import javax.annotation.PostConstruct
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Component // <1>
class LazyComponent {
	@Accessors(PUBLIC_GETTER)
	static String status = "uninitialized"

	@PostConstruct
	def void initialize() {
		status = "initialized"
	}
}

@Component
@Eager // <2>
class EagerComponent {
	@Accessors(PUBLIC_GETTER)
	static String status = "uninitialized"

	@PostConstruct
	def void initialize() {
		status = "initialized"
	}
}

@Module(components=#[LazyComponent, EagerComponent])
interface TestModule {
	def LazyComponent lazyComponent()

	def EagerComponent eagerComponent()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		assertEquals( // <3>
			"uninitialized",
			LazyComponent.status
		)
		assertEquals( // <4>
			"initialized",
			EagerComponent.status
		)
		module.lazyComponent // <5>
		assertEquals( // <6>
			"initialized",
			LazyComponent.status
		)
	}
}
// end::Example[]
