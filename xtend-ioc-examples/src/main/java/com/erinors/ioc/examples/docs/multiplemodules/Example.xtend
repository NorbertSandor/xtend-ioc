package com.erinors.ioc.examples.docs.multiplemodules

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Provider

// tag::Example[]
@Component // <1>
class TestComponent {
	@Inject
	public String value
}

@Component
class Provider1 {
	@Provider // <2>
	def String provider() '''1'''
}

@Component
class Provider2 {
	@Provider // <3>
	def String provider() '''2'''
}

@Module(components=#[TestComponent, Provider1]) // <4>
interface TestModule1 {
	def TestComponent testComponent()
}

@Module(components=#[TestComponent, Provider2]) // <5>
interface TestModule2 {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test() {
		val module1 = TestModule1.Instance.initialize
		val module2 = TestModule2.Instance.initialize
		val testComponent1 = module1.testComponent
		val testComponent2 = module2.testComponent
		assertEquals( // <6>
			"1", testComponent1.value
		)
		assertEquals( // <7>
			"2", testComponent2.value
		)
	}
}
// end::Example[]
