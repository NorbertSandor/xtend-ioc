package com.erinors.ioc.test.integration.case041

import org.junit.Test
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Any
import static org.junit.Assert.*

interface Contract
{
}

@Component
class Component1 implements Contract
{
}

@Component
class Component2 implements Contract
{
}

@Module(components=#[Component1, Component2])
interface TestModule
{
	@Any
	def Contract any()

	def Component1 component1()

	def Component2 component2()
}

class InjectAnyTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		assertTrue(module.any == module.component1 || module.any == module.component2)
	}
}
