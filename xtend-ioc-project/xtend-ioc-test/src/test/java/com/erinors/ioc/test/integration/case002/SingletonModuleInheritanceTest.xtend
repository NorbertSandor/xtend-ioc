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
package com.erinors.ioc.test.integration.case002

import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.test.integration.HelloService
import com.erinors.ioc.test.integration.HelloServiceImpl
import org.junit.Test

import static org.junit.Assert.*

@Module(components=HelloServiceImpl, singleton=true)
interface HelloModule
{
	def HelloService helloService()
}

@Module(singleton=true)
interface MainModule extends HelloModule
{
}

class SingletonModuleInheritanceTest
{
	@Test
	def void test()
	{
		MainModule.Peer.initialize

		assertTrue(MainModule.Peer.get === HelloModule.Peer.get)

		assertEquals("Hello Jeff!", MainModule.Peer.get.helloService.sayHello("Jeff"))

		MainModule.Peer.close

		try
		{
			HelloModule.Peer.get
			fail
		}
		catch (IllegalStateException e)
		{
			// Expected
		}

		try
		{
			MainModule.Peer.get
			fail
		}
		catch (IllegalStateException e)
		{
			// Expected
		}
	}
}
