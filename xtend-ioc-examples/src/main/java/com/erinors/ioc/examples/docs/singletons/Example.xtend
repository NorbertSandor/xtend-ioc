package com.erinors.ioc.examples.docs.singletons

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import org.junit.Assert
import org.junit.Test

// tag::Example[]
@Component // <1>
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
			testComponent1 == testComponent2
		)
	}
}
// end::Example[]
