/*
 * #%L
 * xtend-ioc-test
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.test.integration.case005

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Qualifier
import com.erinors.ioc.test.integration.HelloService
import com.erinors.ioc.test.integration.HelloServiceImpl
import java.lang.annotation.Documented
import java.lang.annotation.Retention
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

@Qualifier
@Documented
@Retention(RUNTIME)
annotation Hungarian {
}

@Qualifier
@Documented
@Retention(RUNTIME)
annotation English {
}

@Component
@English
class EnglishHelloServiceImpl implements HelloService {
	override sayHello(String name) {
		'''Hello «name»!'''
	}
}

@Component
@Hungarian
class HungarianHelloServiceImpl implements HelloService {
	override sayHello(String name) {
		'''Szia «name»!'''
	}
}

@Component
class SomeComponent {
	@Inject
	@English
	public HelloService englishHelloService

	@Hungarian
	@Inject
	public HelloService hungarianHelloService	
}

@Module(components=#[EnglishHelloServiceImpl, HungarianHelloServiceImpl, HelloServiceImpl, SomeComponent])
interface TestModule {
	@English
	def HelloService englishHelloService()

	@Hungarian
	def HelloService hungarianHelloService()

	@English
	def List<HelloService> englishHelloServices()

	@Hungarian
	def List<HelloService> hungarianHelloServices()

	def List<HelloService> helloServices()
}

class QualifierTest {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		assertEquals("Hello Jeff!", module.englishHelloService.sayHello("Jeff"))
		assertEquals("Szia Jeff!", module.hungarianHelloService.sayHello("Jeff"))

		assertEquals(1, module.hungarianHelloServices.size)
		assertEquals(module.hungarianHelloService, module.hungarianHelloServices.head)

		assertEquals(1, module.englishHelloServices.size)
		assertEquals(module.englishHelloService, module.englishHelloServices.head)

		assertEquals(3, module.helloServices.size)
	}
}
