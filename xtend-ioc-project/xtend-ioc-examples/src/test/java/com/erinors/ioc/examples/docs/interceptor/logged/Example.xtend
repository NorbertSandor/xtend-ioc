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
import static org.junit.Assert.*
import org.junit.Test

// tag::Example[]
@Interceptor(LoggedInvocationHandler) // <1>
annotation Logged {
}

@Component // <2>
class LoggedInvocationHandler implements InterceptorInvocationHandler<LoggedInvocationPointConfiguration> // <3>
{
	@Inject // <4>
	Logger logger

	override handle(
		LoggedInvocationPointConfiguration invocationPointConfiguration, // <5>
		InvocationContext context // <6>
	) {
		logger.log('''>> «invocationPointConfiguration.methodName»(«context.arguments.join(", ")»)''')
		try {
			val returned = context.proceed // <7>
			logger.log('''<< «invocationPointConfiguration.methodName»: «returned»''')
			return returned // <8>
		} catch (Exception e) {
			logger.log('''!! «invocationPointConfiguration.methodName»: «e.message»''')
			throw e
		}
	}
}

@Component // <9>
class Logger {
	val buffer = new StringBuilder

	def void log(String message) {
		buffer.append(message)
		buffer.append(System.lineSeparator)
	}

	def String getBuffer() {
		buffer.toString
	}
}

@Component
class SomeComponent {
	@Logged // <10>
	def int method(int value, boolean fail) {
		if (fail)
			throw new IllegalStateException("Failed!")
		else
			value * 2
	}
}

@Module(components=#[SomeComponent, Logger]) // <11>
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
			>> method(3, false)
			<< method: 6
			>> method(3, true)
			!! method: Failed!
		'''.toString, m.logger.buffer)
	}
}
// end::Example[]
