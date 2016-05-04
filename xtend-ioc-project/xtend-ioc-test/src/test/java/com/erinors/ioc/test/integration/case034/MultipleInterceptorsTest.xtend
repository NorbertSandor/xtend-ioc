/*
 * #%L
 * xtend-ioc-test
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.test.integration.case034

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.InterceptorInvocationHandler
import com.erinors.ioc.shared.api.InvocationContext
import com.erinors.ioc.shared.api.MethodReference
import com.erinors.ioc.shared.api.Module
import org.junit.Test

import static org.junit.Assert.*

@Interceptor(CustomInterceptor1InvocationHandler)
annotation CustomInterceptor1
{
	@MethodReference(returnType=void, parameterTypes=#[
		String])
	String handlerMethod
}

@Interceptor(CustomInterceptor2InvocationHandler)
annotation CustomInterceptor2
{
	@MethodReference(returnType=void, parameterTypes=#[
		String])
	String handlerMethod
}

@Component
class CustomInterceptor1InvocationHandler implements InterceptorInvocationHandler<CustomInterceptor1InvocationPointConfiguration>
{
	override handle(CustomInterceptor1InvocationPointConfiguration invocationPointConfiguration,
		InvocationContext context)
	{
		invocationPointConfiguration.handlerMethod.apply("1" + context.arguments.get(0) as String)
		context.proceed
	}
}

@Component
class CustomInterceptor2InvocationHandler implements InterceptorInvocationHandler<CustomInterceptor2InvocationPointConfiguration>
{
	override handle(CustomInterceptor2InvocationPointConfiguration invocationPointConfiguration,
		InvocationContext context)
	{
		invocationPointConfiguration.handlerMethod.apply("2" + context.arguments.get(0) as String)
		context.proceed
	}
}

@Component
class Component1
{
	var public String text = ""

	@CustomInterceptor1(handlerMethod="handler")
	@CustomInterceptor2(handlerMethod="handler")
	def void method(String value)
	{
	}

	def private void handler(String value)
	{
		text += value
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
		
		component1.method("a")
		assertEquals("1a2a", component1.text)
	}
}
