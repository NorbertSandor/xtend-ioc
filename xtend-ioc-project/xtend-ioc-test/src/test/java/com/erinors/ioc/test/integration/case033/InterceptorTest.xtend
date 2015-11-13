/*
 * #%L
 * xtend-ioc-test
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.test.integration.case033

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.InterceptorInvocationHandler
import com.erinors.ioc.shared.api.InvocationContext
import com.erinors.ioc.shared.api.MethodReference
import com.erinors.ioc.shared.api.Module
import org.junit.Test

import static org.junit.Assert.*

@Interceptor(CustomInterceptorInvocationHandler)
annotation CustomInterceptor
{
	@MethodReference(returnType=void, parameterTypes=#[
		int])
	String handlerMethod
}

@Component
class CustomInterceptorInvocationHandler implements InterceptorInvocationHandler<CustomInterceptorInvocationPointConfiguration>
{
	override handle(CustomInterceptorInvocationPointConfiguration invocationPointConfiguration,
		InvocationContext context)
	{
		invocationPointConfiguration.handlerMethod.apply(context.arguments.get(0) as Integer)
		context.proceed
	}
}

@Component
class Component1
{
	var public int count = 0

	@CustomInterceptor(handlerMethod="counter")
	def int method(int value)
	{
		11 * value
	}

	def private void counter(int value)
	{
		count += value
	}
}

@Module(components=#[Component1])
interface TestModule
{
	def Component1 component1()
}

class InterceptorTest
{
	@Test
	def void testComponentWithLoggedMethod()
	{
		val module = TestModule.Peer.initialize
		val component1 = module.component1
		
		val result = component1.method(13)
		assertEquals(11 * 13, result)

		component1.method(5)

		assertEquals(13 + 5, component1.count)
	}
}
