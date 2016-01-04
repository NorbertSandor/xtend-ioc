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
package com.erinors.ioc.examples.docs.interceptor.logged

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.InterceptorInvocationHandler
import com.erinors.ioc.shared.api.InvocationContext
import com.erinors.ioc.shared.api.Module
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Interceptor(LoggedInvocationHandler) // <1>
annotation Logged {
	String loggerName = "test" // <2>
}

@Component // <3>
class LoggedInvocationHandler implements InterceptorInvocationHandler<LoggedInvocationPointConfiguration> // <4>
{
	@Inject // <5>
	Logger logger

	override handle(
		LoggedInvocationPointConfiguration invocationPointConfiguration, // <6>
		InvocationContext context // <7>
	) {
		val loggerName = invocationPointConfiguration.loggerName // <8>
		logger.log(loggerName, '''>> «invocationPointConfiguration.methodName»(«context.arguments.join(", ")»)''')
		try {
			val returned = context.proceed // <9>
			logger.log(loggerName, '''<< «invocationPointConfiguration.methodName»: «returned»''')
			return returned // <10>
		} catch (Exception e) {
			logger.log(loggerName, '''!! «invocationPointConfiguration.methodName»: «e.message»''')
			throw e
		}
	}
}

@Component // <11>
class Logger {
	val buffer = new StringBuilder

	def void log(String loggerName, String message) {
		buffer.append(
		'''
			[«loggerName»] «message»
		''')
	}

	def String getBuffer() {
		buffer.toString
	}
}

@Component
class SomeComponent {
	@Logged // <12>
	def int method(int value, boolean fail) {
		if (fail)
			throw new IllegalStateException("Failed!")
		else
			value * 2
	}
}

@Module(components=#[SomeComponent, Logger]) // <13>
interface TestModule {
	def SomeComponent someComponent()

	def Logger logger()
}

class LoggedExample {
	@Test
	def void test() {
		val m = TestModule.Peer.initialize

		assertEquals(6, m.someComponent.method(3, false))

		try {
			m.someComponent.method(3, true)
			fail
		} catch (Exception e) {
		}

		assertEquals('''
			[test] >> method(3, false)
			[test] << method: 6
			[test] >> method(3, true)
			[test] !! method: Failed!
		'''.toString, m.logger.buffer)
	}
}
// end::Example[]
