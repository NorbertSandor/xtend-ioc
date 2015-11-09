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
package com.erinors.ioc.examples.docs.lifecycle

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test
import javax.annotation.PostConstruct
import javax.annotation.PreDestroy
import org.eclipse.xtend.lib.annotations.Accessors

// tag::Example[]
@Component // <1>
class TestComponent {
	@Accessors(PUBLIC_GETTER)
	static String status = "uninitialized" // <2>

	@PostConstruct // <3>
	def void initialize() {
		status = "initialized"
	}

	@PreDestroy // <4>
	def void close() {
		status = "closed"
	}
}

@Module(components=TestComponent)
interface TestModule {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize // <5>
		assertEquals("uninitialized", TestComponent.status) // <6>
		module.testComponent // <7>
		assertEquals("initialized", TestComponent.status)
		module.close // <8>
		assertEquals("closed", TestComponent.status)
	}
}
// end::Example[]
