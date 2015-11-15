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
package com.erinors.ioc.examples.docs.interceptor.profiled

import com.erinors.ioc.examples.docs.interceptor.logged.Logger
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.InterceptorInvocationHandler
import com.erinors.ioc.shared.api.InvocationContext
import com.erinors.ioc.shared.api.Module

import static org.junit.Assert.*
import org.junit.Test

// tag::Example[]
@Interceptor(ProfiledInvocationHandler)
annotation Profiled {
}

@Component
class ProfiledInvocationHandler implements InterceptorInvocationHandler<ProfiledInvocationPointConfiguration> {
	@Inject
	Logger logger

	override handle(
		ProfiledInvocationPointConfiguration invocationPointConfiguration,
		InvocationContext context
	) {
		val start = System.currentTimeMillis
		logger.log("test", "Started profiling")
		try {
			context.proceed
		} finally {
			logger.log("test", '''Elapsed «System.currentTimeMillis-start»ms''')
		}
	}
}

@Component
class SomeComponent {
	@Profiled
	def void sleep(long waitMillis) {
		Thread.sleep(waitMillis) // <2>
	}
}

@Module(components=#[SomeComponent, Logger])
interface TestModule {
	def SomeComponent someComponent()

	def Logger logger()
}

class ProfiledExample {
	@Test
	def void test() {
		val m = TestModule.Peer.initialize

		m.someComponent.sleep(100)
		m.someComponent.sleep(300)

		assertTrue(m.logger.buffer.matches('''
			\[test\] Started profiling
			\[test\] Elapsed 1..ms
			\[test\] Started profiling
			\[test\] Elapsed 3..ms
		'''))
	}
}
// end::Example[]
