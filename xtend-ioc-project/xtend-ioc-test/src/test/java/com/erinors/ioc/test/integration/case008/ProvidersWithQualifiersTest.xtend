/*
 * #%L
 * xtend-ioc-test
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.test.integration.case008

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.api.Qualifier
import com.erinors.ioc.test.integration.HelloService
import java.lang.annotation.Documented
import java.lang.annotation.Retention
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

@Qualifier
@Documented
@Retention(RUNTIME)
annotation Language {
	String value
}

class HelloServiceImpl implements HelloService {
	override sayHello(String name) {
		'''Hello «name»!'''
	}
}

@Component
class HelloServiceProviderImpl {
	@Provider
	@Language("hu")
	def HelloService helloServiceHu() {
		new HelloService() {
			override sayHello(String name) {
				'''Szia «name»!'''
			}
		}
	}

	@Provider
	@Language("en")
	def HelloService helloServiceEn() {
		new HelloServiceImpl
	}
}

@Module(components=HelloServiceProviderImpl)
interface TestModule {
	@Language("hu")
	def HelloService helloServiceHu()

	@Language("en")
	def HelloService helloServiceEn()

	def List<? extends HelloService> helloServices()
}

class ProvidersWithQualifiersTest {
	@Test
	def void teste() {
		val module = TestModule.Peer.initialize
		assertEquals("Hello Jeff!", module.helloServiceEn.sayHello("Jeff"))
		assertEquals("Szia Jeff!", module.helloServiceHu.sayHello("Jeff"))
		assertEquals(2, module.helloServices.size)
	}
}
