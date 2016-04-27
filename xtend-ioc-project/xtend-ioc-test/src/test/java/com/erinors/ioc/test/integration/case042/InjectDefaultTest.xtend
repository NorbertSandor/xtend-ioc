package com.erinors.ioc.test.integration.case042

import org.junit.Test
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Any
import static org.junit.Assert.*
import com.erinors.ioc.shared.api.Qualifier
import com.erinors.ioc.impl.Default

@Qualifier
annotation Transactional
{
}

interface Contract
{
}

@Component
class Component1 implements Contract
{
}

@Component
@Transactional
class Component2 implements Contract
{
}

@Module(components=#[Component1, Component2])
interface TestModule
{
	@Any
	def Contract any()

	@Transactional
	def Contract transactionalComponent()

	@Default
	def Contract defaultComponent()

	def Component1 component1()

	def Component2 component2()
}

class InjectDefaultTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		assertTrue(module.any == module.transactionalComponent || module.any == module.defaultComponent)
		assertTrue(module.component1 == module.defaultComponent)
		assertTrue(module.component2 == module.transactionalComponent)
	}
}
