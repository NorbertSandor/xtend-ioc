package com.erinors.ioc.examples.docs.avoiddependencygraphcycle

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Supplier
import javax.annotation.PostConstruct
import org.junit.Test

import static org.junit.Assert.*

//
// Note this file and /xtend-ioc-core/src/test/java/com/erinors/ioc/impl/CycleDetectionTest.xtend should stay in sync!
//

// tag::Example[]
@Module(nonAbstract=false)
interface AbstractModule {
	def Supplier<Component4> component4Supplier() // <1>
}

@Component
class Component1 {
	// Direct injection is not allowed because it would cause two cycles in the dependency graph 
	// @Inject // <2>
	// Component4 component4
	
	Supplier<Component4> component4Supplier

	@PostConstruct
	def void initialize() {
		component4Supplier = AbstractModule.Instance.get.component4Supplier // <3>
		// component4Supplier.get <4>
	}

	def boolean someBusinessMethod() {
		!component4Supplier.get.anotherBusinessMethod // <5>
	}
}

@Component
class Component2 {
	@Inject
	public Component1 component1
}

@Component
class Component3 {
	@Inject
	public Component1 component1

	@Inject
	public Component2 component2
}

@Component
class Component4 {
	@Inject
	public Component3 component3

	def anotherBusinessMethod() {
		true
	}
}

@Module(components=#[Component1, Component2, Component3, Component4])
interface TestModule extends AbstractModule // <6>
{
	def Component1 component1()
}

class AvoidDependencyGraphCycleTest {
	@Test
	def void test() {
		val module = TestModule.Instance.initialize
		assertFalse(module.component1.someBusinessMethod) // <7>
	}
}
// end::Example[]
