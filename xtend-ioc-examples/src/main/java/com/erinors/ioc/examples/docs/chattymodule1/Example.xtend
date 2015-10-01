package com.erinors.ioc.examples.docs.chattymodule1

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import java.util.List
import org.junit.Test
import static org.junit.Assert.*
import com.erinors.ioc.shared.api.Inject

// tag::ChattyModule[]
interface HelloService { // <1>
	def String sayHello(String name)
}

@Component // <2>
class EnglishHelloServiceImpl implements HelloService {
	override sayHello(String name) '''Hello «name»!'''
}

@Component
class HungarianHelloServiceImpl implements HelloService {
	override sayHello(String name) '''Szia «name»!'''
}

@Component
class AnotherComponent {
	@Inject
	public EnglishHelloServiceImpl englishHelloService // <3>
}

@Module( // <4>
components=#[EnglishHelloServiceImpl, HungarianHelloServiceImpl, AnotherComponent] // <5>
)
interface ChattyModule {
	def EnglishHelloServiceImpl englishHelloService() // <6>

	def HungarianHelloServiceImpl hungarianHelloService() // <7>

	def List<? extends HelloService> helloServices() // <8>

	def AnotherComponent anotherComponent()
}

class ChattyModuleTest {
	@Test
	def void test() {
		val module = ChattyModule.Instance.initialize // <9>
		assertEquals("Hello Jeff!", module.englishHelloService.sayHello("Jeff")) // <10>
		assertEquals("Szia Jeff!", module.hungarianHelloService.sayHello("Jeff")) // <11>
		assertEquals(2, module.helloServices.size) // <12>
		assertTrue(
			module.englishHelloService == module.anotherComponent.englishHelloService // <13>
		)
	}
}
// end::ChattyModule[]
