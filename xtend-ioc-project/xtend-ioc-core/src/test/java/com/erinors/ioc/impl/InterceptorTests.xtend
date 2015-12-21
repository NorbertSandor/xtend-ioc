/*
 * #%L
 * xtend-ioc-core
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.impl

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.InterceptorInvocationHandler
import com.erinors.ioc.shared.api.InvocationContext
import com.erinors.ioc.shared.api.MethodReference
import com.erinors.ioc.shared.api.Module
import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.junit.Test

import static org.junit.Assert.*

class InterceptorTests
{
	extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

	@Test
	def void testInterceptorReferencedMethodShouldNotHaveMoreThanSixAttributes()
	{
		compilerTester.compile(
		'''
			import «Component.name»
			import «Interceptor.name»
			import «InterceptorInvocationHandler.name»
			import «InvocationContext.name»
			import «MethodReference.name»
			import «Module.name»
			
			@Interceptor(CustomInterceptorInvocationHandler)
			annotation CustomInterceptor
			{
				@MethodReference(returnType=void, parameterTypes=#[int, int, int, int, int, int, int])
				String handlerMethod
			}
			
			@Component
			class CustomInterceptorInvocationHandler implements InterceptorInvocationHandler<CustomInterceptorInvocationPointConfiguration>
			{
				override handle(CustomInterceptorInvocationPointConfiguration invocationPointConfiguration,
					InvocationContext context)
				{
					invocationPointConfiguration.handlerMethod.apply(0, 1, 2, 3, 4, 5, 6)
				}
			}
			
			@Component
			class Component1
			{
				@CustomInterceptor(handlerMethod="handler")
				def void method()
				{
				}
				
				def private void handler(int p0, int p1, int p2, int p3, int p4, int p5, int p6)
				{
				}
			}
			
			@Module(components=#[Component1])
			interface TestModule
			{
				def Component1 component1()
			}
		''', [
			assertEquals(1, allProblems.size)
			assertEquals("Referenced methods may have at most 6 parameters.", allProblems.get(0).message)
		])
	}
}
