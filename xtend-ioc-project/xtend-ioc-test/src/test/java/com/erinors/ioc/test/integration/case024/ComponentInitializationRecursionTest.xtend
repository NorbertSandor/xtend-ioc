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
package com.erinors.ioc.test.integration.case024

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Supplier
import javax.annotation.PostConstruct
import org.junit.Test

@Component
class Component1
{
	@PostConstruct
	def void initialize()
	{
		AbstractModule.Peer.get.component4Supplier.get
	}
}

@Component
class Component2
{
	@Inject
	public Component1 component1
}

@Component
class Component3
{
	@Inject
	public Component1 component1

	@Inject
	public Component2 component2
}

@Component
class Component4
{
	@Inject
	public Component3 component3
}

@Module(isAbstract=true)
interface AbstractModule
{
	def Supplier<Component4> component4Supplier()
}

@Module(components=#[Component1, Component2, Component3, Component4])
interface TestModule extends AbstractModule
{
	def Component1 component1()
}

class ComponentInitializationRecursionTest
{
	@Test(expected=IllegalStateException)
	def void test()
	{
		TestModule.Peer.initialize.component1
	}
}
