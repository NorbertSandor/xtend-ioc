package com.erinors.ioc.examples.docs.supplier

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Supplier
import org.junit.Assert
import org.junit.Test

// tag::Example[]
interface Handler<T> {}

@Component
class AnotherComponent {
}

@Component
class TestComponent {
	@Inject // <1>
	public Supplier<AnotherComponent> componentSupplier

	@Inject
	public AnotherComponent injectedComponent
}

@Module(components=#[AnotherComponent, TestComponent])
interface TestModule {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test()	{
		val module = TestModule.Instance.initialize
		val testComponent = module.testComponent
		Assert.assertTrue( // <2>
			testComponent.injectedComponent == testComponent.componentSupplier.get
		)
	}
}
// end::Example[]
