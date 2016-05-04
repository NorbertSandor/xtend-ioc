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
package com.erinors.ioc.examples.docs.interceptor.multiple

import com.erinors.ioc.examples.docs.interceptor.logged.Logged
import com.erinors.ioc.examples.docs.interceptor.logged.Logger
import com.erinors.ioc.examples.docs.interceptor.profiled.Profiled
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Component
class SomeComponent {
	@Profiled
	@Logged
	def void sleep1(long waitMillis) { // <1>
		Thread.sleep(waitMillis)
	}

	@Logged
	@Profiled
	def void sleep2(long waitMillis) { // <2>
		Thread.sleep(waitMillis)
	}
}

@Module(components=#[SomeComponent, Logger])
interface TestModule {
	def SomeComponent someComponent()

	def Logger logger()
}

class MultipleInterceptorsExample {
	@Test
	def void testSleep1() {
		val m = TestModule.Peer.initialize

		m.someComponent.sleep1(100)

		assertTrue(m.logger.buffer.matches('''
			\[test\] Started profiling
			\[test\] >> sleep1\(100\)
			\[test\] << sleep1: 
			\[test\] Elapsed 1..ms
		''')) // <3>
		
		TestModule.Peer.close
	}

	@Test
	def void testSleep2() {
		val m = TestModule.Peer.initialize

		m.someComponent.sleep2(100)

		assertTrue(m.logger.buffer.matches('''
			\[test\] >> sleep2\(100\)
			\[test\] Started profiling
			\[test\] Elapsed 1.?.?ms
			\[test\] << sleep2: 
		''')) // <4>
		
		TestModule.Peer.close
	}
}
// end::Example[]
