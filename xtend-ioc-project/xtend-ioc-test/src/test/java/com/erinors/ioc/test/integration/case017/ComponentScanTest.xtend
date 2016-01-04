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
package com.erinors.ioc.test.integration.case017

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import java.util.List
import org.junit.Assert
import org.junit.Test

interface ComponentInterface {}

@Component
class Component1 implements ComponentInterface
{
}

@Component
class Component2 implements ComponentInterface
{
}

@Module(componentScanClasses=TestModule)
interface TestModule
{
	def List<ComponentInterface> components()
}

class ComponentScanTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		Assert.assertEquals(3, module.components.size)
	}
}
