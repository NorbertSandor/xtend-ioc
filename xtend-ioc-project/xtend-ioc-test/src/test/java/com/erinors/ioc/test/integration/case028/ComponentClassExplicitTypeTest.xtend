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
package com.erinors.ioc.test.integration.case028

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

interface ComponentInterface1
{
}

interface ComponentInterface2
{
}

@Component(type=ComponentInterface1)
class Component1 implements ComponentInterface1, ComponentInterface2
{
}

@Component(type=ComponentInterface2)
class Component2 implements ComponentInterface1, ComponentInterface2
{
}

@Component
class ComponentNoExplicitType implements ComponentInterface1, ComponentInterface2
{
}

@Module(components=#[Component1, Component2, ComponentNoExplicitType])
interface TestModule
{
	def List<ComponentInterface1> componentInterface1List()

	def List<ComponentInterface2> componentInterface2List()
}

class ComponentClassExplicitTypeTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		assertEquals(2, module.componentInterface1List.size)
		assertEquals(2, module.componentInterface2List.size)
	}
}
