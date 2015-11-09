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
package com.erinors.ioc.test.integration.case007

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.test.integration.HelloService
import org.junit.Test

import static org.junit.Assert.*

class HelloServiceImpl implements HelloService {
	override sayHello(String name) {
		'''Hello «name»!'''
	}
}

@Component
class HelloServiceProviderImpl {
	@Provider
	def HelloService helloService() {
		new HelloServiceImpl
	}
}

@Module(components=HelloServiceProviderImpl)
interface TestModule {
	def HelloService helloService()
}

class ProviderTest {
	@Test
	def void testSimpleModule() {
		assertEquals("Hello Jeff!", TestModule.Peer.initialize.helloService.sayHello("Jeff"))
	}
}
