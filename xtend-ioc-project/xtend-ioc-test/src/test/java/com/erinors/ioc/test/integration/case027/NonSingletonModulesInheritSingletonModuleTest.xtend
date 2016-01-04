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
package com.erinors.ioc.test.integration.case027

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

@Module(singleton=false)
interface MainModule1 extends HelloModule
{
}

@Module(singleton=false)
interface MainModule2 extends HelloModule
{
}

class NonSingletonModulesInheritSingletonModuleTest
{
	@Test
	def void test()
	{
		MainModule1.Peer.constructInstance

		try
		{
			MainModule2.Peer.constructInstance
			fail
		}
		catch (Exception e)
		{
			// Expected
		}
	}
}
