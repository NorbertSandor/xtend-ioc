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
		TestModule.Peer.initialize // <2>
		assertTrue(TestModule.Peer.get === ParentModule.Peer.get) // <3>
		assertTrue( // <4>
			TestModule.Peer.get.testComponent ===
			ParentModule.Peer.get.testComponent
		)
	}
}
// end::Example[]
