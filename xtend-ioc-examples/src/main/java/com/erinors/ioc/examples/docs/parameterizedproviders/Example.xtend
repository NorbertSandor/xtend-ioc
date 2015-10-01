package com.erinors.ioc.examples.docs.parameterizedproviders

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.ParametrizedQualifier
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.api.Qualifier
import java.util.Properties
import javax.annotation.PostConstruct
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Qualifier // <1>
annotation ConfigurationValue {
	String value
}

@Component
class ProviderComponent {
	Properties configuration

	@PostConstruct
	def void initialize() {
		// In a real provider the configuration would be loaded from a file
		configuration = new Properties
		configuration.setProperty("a", "A")
		configuration.setProperty("b", "B")
	}

	@Provider( // <2>
	parametrizedQualifiers=@ParametrizedQualifier(qualifier=ConfigurationValue, // <3>
	attributeName="value", // <4>
	parameterName="configurationName" // <5>
	))
	def String configurationValueProvider(String configurationName) {
		return configuration.getProperty(configurationName)
	}
}

@Component // <6>
class TestComponent {
	@Inject
	@ConfigurationValue("a")
	public String a

	@Inject
	@ConfigurationValue("b")
	public String b
}

@Module(components=#[ProviderComponent, TestComponent])
interface TestModule {
	def TestComponent testComponent()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Instance.initialize
		val testComponent = module.testComponent
		assertEquals("A", testComponent.a) // <7>
		assertEquals("B", testComponent.b)
	}
}
// end::Example[]
