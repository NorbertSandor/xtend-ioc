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
package com.erinors.ioc.test.integration.case003

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.test.integration.GoodbyeService
import com.erinors.ioc.test.integration.GoodbyeServiceImpl
import com.erinors.ioc.test.integration.HelloService
import com.erinors.ioc.test.integration.HelloServiceImpl
import org.junit.Test

import static org.junit.Assert.*

interface ConversationService {
	def String say(String name)
}

@Component
class ConversationServiceImpl implements ConversationService {
	@Inject
	HelloService helloService

	val GoodbyeService goodbyeService

	@Inject
	new(GoodbyeService goodbyeService) {
		this.goodbyeService = goodbyeService
	}

	override say(String name) '''
		- «helloService.sayHello(name)»
		- «goodbyeService.sayGoodbye(name)»
	'''
}

@Module(components=#[HelloServiceImpl, GoodbyeServiceImpl])
interface CoreModule {
}

@Module(components=ConversationServiceImpl)
interface MainModule extends CoreModule {
	def ConversationService conversationService()
}

class ComponentDependencyTest {
	@Test
	def void testSimpleModule() {
		assertEquals(
		'''
			- Hello Jeff!
			- Goodbye Jeff!
		'''.toString, MainModule.Peer.initialize.conversationService.say("Jeff"))
	}
}
