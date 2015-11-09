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
package com.erinors.ioc.examples.docs.moduleinheritance

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test

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
		assertNotNull( // <2>
			TestModule.Peer.initialize.testComponent
		)
	}
}
// end::Example[]
