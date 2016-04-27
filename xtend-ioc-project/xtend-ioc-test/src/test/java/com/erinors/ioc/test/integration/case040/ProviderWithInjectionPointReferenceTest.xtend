package com.erinors.ioc.test.integration.case040

import org.junit.Test
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Qualifier
import com.erinors.ioc.shared.api.Provider
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import com.erinors.ioc.shared.api.ParameterizedQualifier
import static org.junit.Assert.*
import com.erinors.ioc.shared.api.InjectionPoint
import com.erinors.ioc.shared.api.DeclaredInjectionPoint

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
}

@Module(components=#[LoggerProvider])
interface TestModule
{
	@LoggerByClass
	def Logger defaultLogger()

	@LoggerByClass(Integer)
	def Logger explicitLogger()
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
