package com.erinors.ioc.examples.docs.injectionforpojos

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Injectable
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Provider
import static org.junit.Assert.*
import org.junit.Test
import org.eclipse.xtend.lib.annotations.Data

// tag::Example[]
@Component
class ValueProvider {
	@Provider
	def String value() '''a'''
}

@Module(components=ValueProvider)
interface TestModule { // <1>
	def String value()
}

@Injectable(TestModule) // <2>
class Injectable1 {
	@Inject
	public String value
}

@Data
@Injectable(TestModule) // <3>
class Injectable2 {
	String value

	@Inject
	new(String value) {
		this.value = value
	}
}

@Data
@Injectable(TestModule) // <4>
class Injectable3 {
	int number

	String value

	new(int number, @Inject String value) {
		this.number = number
		this.value = value
	}
}

class Example {
	@Test
	def void test() {
		TestModule.Instance.initialize // <5>
		assertEquals("a", new Injectable1().value) // <6>
		assertEquals("a", new Injectable2().value) // <7>
		assertEquals("a", new Injectable3(1).value) // <8>
	}
}
// end::Example[]
