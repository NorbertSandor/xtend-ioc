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
package com.erinors.ioc.test.integration.case040

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.DeclaredInjectionPoint
import com.erinors.ioc.shared.api.InjectionPoint
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.ParameterizedQualifier
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.api.Qualifier
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.junit.Test

import static org.junit.Assert.*

@Qualifier
annotation LoggerByClass
{
	Class<?> value = Object
}

@FinalFieldsConstructor
class Logger
{
	val String loggerName

	def String log(
		String message)
	{
		'''[«loggerName»] «message»'''
	}
}

@Component
class LoggerProvider
{
	@Provider(parameterizedQualifiers=@ParameterizedQualifier(attributeName="value", qualifier=LoggerByClass, parameterIndex=0))
	def Logger logger(Class<?> clazz, InjectionPoint injectionPoint)
	{
		if (injectionPoint instanceof DeclaredInjectionPoint)
		{
			new Logger(if (clazz == Object) injectionPoint.declaringClass.simpleName else clazz.simpleName)
		}
		else
		{
			throw new IllegalStateException()
		}
	}
	
	@Provider
	def Logger logger(InjectionPoint injectionPoint) {
		if (injectionPoint instanceof DeclaredInjectionPoint)
		{
			new Logger(injectionPoint.declaringClass.simpleName)
		}
		else
		{
			throw new IllegalStateException()
		}
	}
}

@Module(components=#[LoggerProvider])
interface TestModule
{
	@LoggerByClass
	def Logger defaultLogger()

	@LoggerByClass(Integer)
	def Logger explicitLogger()

	// TODO use @Default def Logger loggerWithoutQualifiers()
}

class ProviderWithInjectionPointReferenceTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		assertEquals("[TestModule] blabla", module.defaultLogger.log("blabla"))
		assertEquals("[Integer] blabla", module.explicitLogger.log("blabla"))
	}
}
