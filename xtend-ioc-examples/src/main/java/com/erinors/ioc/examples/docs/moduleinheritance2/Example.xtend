package com.erinors.ioc.examples.docs.moduleinheritance2

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test

// tag::Example[]
@Component
class TestComponent {
}

@Module(components=TestComponent)
interface ParentModule {
	def TestComponent testComponent()
}

@Module // <1>
interface TestModule extends ParentModule {
}

class Example {
	@Test
	def void test() {
		TestModule.Instance.initialize // <2>
		assertTrue(TestModule.Instance.get === ParentModule.Instance.get) // <3>
		assertTrue( // <4>
			TestModule.Instance.get.testComponent ===
			ParentModule.Instance.get.testComponent
		)
	}
}
// end::Example[]
