package com.erinors.ioc.examples.docs.componentscan

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
interface SomeInterface {
}

@Component
class Component1 implements SomeInterface {
}

@Component
class Component2 implements SomeInterface {
}

@Module(componentScanClasses=TestModule) // <1>
interface TestModule {
	def List<SomeInterface> instances()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Instance.initialize
		assertEquals(2, module.instances.size) // <2>
	}
}
// end::Example[]
