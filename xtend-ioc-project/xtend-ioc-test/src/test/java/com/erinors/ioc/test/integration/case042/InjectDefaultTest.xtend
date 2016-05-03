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
package com.erinors.ioc.test.integration.case042

import com.erinors.ioc.shared.api.Default
import com.erinors.ioc.shared.api.Any
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Qualifier
import org.junit.Test

import static org.junit.Assert.*

@Qualifier
annotation Transactional
{
}

interface Contract
{
}

@Component
class Component1 implements Contract
{
}

@Component
@Transactional
class Component2 implements Contract
{
}

@Module(components=#[Component1, Component2])
interface TestModule
{
	@Any
	def Contract any()

	@Transactional
	def Contract transactionalComponent()

	@Default
	def Contract defaultComponent()

	def Component1 component1()

	def Component2 component2()
}

class InjectDefaultTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		assertTrue(module.any == module.transactionalComponent || module.any == module.defaultComponent)
		assertTrue(module.component1 == module.defaultComponent)
		assertTrue(module.component2 == module.transactionalComponent)
	}
}
