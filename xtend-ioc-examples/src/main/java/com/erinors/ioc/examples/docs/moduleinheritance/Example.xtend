package com.erinors.ioc.examples.docs.moduleinheritance

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
		assertNotNull( // <2>
			TestModule.Instance.initialize.testComponent
		)
	}
}
// end::Example[]
