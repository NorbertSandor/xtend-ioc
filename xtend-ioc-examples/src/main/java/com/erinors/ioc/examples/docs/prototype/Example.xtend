package com.erinors.ioc.examples.docs.prototype

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import org.junit.Assert
import org.junit.Test
import com.erinors.ioc.shared.api.Prototype

// tag::Example[]
@Component
@Prototype // <1>
class TestComponent {
}

@Module(components=TestComponent)
interface TestModule {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test()	{
		val module = TestModule.Instance.initialize
		val testComponent1 = module.testComponent
		val testComponent2 = module.testComponent
		Assert.assertTrue( // <2>
			testComponent1 != testComponent2
		)
	}
}
// end::Example[]
