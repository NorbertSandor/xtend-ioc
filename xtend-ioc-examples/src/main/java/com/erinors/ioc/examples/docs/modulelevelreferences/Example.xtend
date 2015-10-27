package com.erinors.ioc.examples.docs.modulelevelreferences

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test
import com.google.common.base.Supplier

// tag::Example[]
interface SomeInterface {
}

@Component
class TestComponent implements SomeInterface {
}

@Module(components=TestComponent)
interface TestModule { // <1>
	def TestComponent testComponent()

	def SomeInterface someInterface()

	def Supplier<SomeInterface> someInterfaceSupplier()
}

class Example {
	@Test
	def void test() { // <2>
		val module = TestModule.Peer.initialize
		assertTrue(module.testComponent === module.someInterface)
		assertTrue(module.testComponent === module.someInterfaceSupplier.get)
	}
}
// end::Example[]
