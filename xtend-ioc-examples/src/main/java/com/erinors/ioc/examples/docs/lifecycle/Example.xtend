package com.erinors.ioc.examples.docs.lifecycle

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import static org.junit.Assert.*
import org.junit.Test
import javax.annotation.PostConstruct
import javax.annotation.PreDestroy
import org.eclipse.xtend.lib.annotations.Accessors

// tag::Example[]
@Component // <1>
class TestComponent {
	@Accessors(PUBLIC_GETTER)
	static String status = "uninitialized" // <2>

	@PostConstruct // <3>
	def void initialize() {
		status = "initialized"
	}

	@PreDestroy // <4>
	def void close() {
		status = "closed"
	}
}

@Module(components=TestComponent)
interface TestModule {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Instance.initialize // <5>
		assertEquals("uninitialized", TestComponent.status) // <6>
		module.testComponent // <7>
		assertEquals("initialized", TestComponent.status)
		module.close // <8>
		assertEquals("closed", TestComponent.status)
	}
}
// end::Example[]
