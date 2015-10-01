package com.erinors.ioc.examples.docs.abstractmodule

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test
import com.erinors.ioc.shared.api.Inject

// tag::Example[]
interface SomeService {
}

@Component
class TestComponent {
	@Inject
	public SomeService someService
}

@Module(components=TestComponent, instantiatable=false) // <1>
interface ParentModule {
	def TestComponent testComponent()
}

@Component
class SomeServiceComponent implements SomeService {
}

@Module(components=SomeServiceComponent)
interface TestModule extends ParentModule {
	def SomeService someService()
}

class Example {
	@Test
	def void test() {
		// Compile-time error: ParentModule.Instance.initialize() <2>
		val module = TestModule.Instance.initialize
		assertTrue(TestModule.Instance.get === ParentModule.Instance.get) // <3>
		assertTrue(module.testComponent.someService === module.someService) // <4>
	}
}
// end::Example[]
