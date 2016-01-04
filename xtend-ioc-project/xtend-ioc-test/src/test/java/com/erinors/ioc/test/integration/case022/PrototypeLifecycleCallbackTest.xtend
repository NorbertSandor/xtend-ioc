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
package com.erinors.ioc.test.integration.case022

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Prototype
import com.google.common.base.Supplier
import javax.annotation.PostConstruct
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test

import static org.junit.Assert.*

@Component
@Prototype
class PrototypeComponent
{
	@Accessors
	String postconstruct = ""

	@PostConstruct
	def void initialize2()
	{
		postconstruct += "2"
	}

	@PostConstruct
	def void initialize1()
	{
		postconstruct += "1"
	}
}

@Module(components=#[PrototypeComponent])
interface TestModule
{
	def PrototypeComponent prototypeComponent()

	def Supplier<PrototypeComponent> prototypeComponentSupplier()
}

class PrototypeLifecycleCallbackTest
{
	@Test
	def void testSimpleModule()
	{
		val module = TestModule.Peer.initialize

		val instance1 = module.prototypeComponent
		assertEquals("21", instance1.postconstruct)

		val instance2 = module.prototypeComponent
		assertEquals("21", instance2.postconstruct)

		assertTrue(instance1 !== instance2)

		val instance3 = module.prototypeComponentSupplier.get
		assertEquals("21", instance3.postconstruct)

		assertTrue(instance2 !== instance3)

		val instance4 = module.prototypeComponentSupplier.get
		assertEquals("21", instance4.postconstruct)

		assertTrue(instance3 !== instance4)
	}
}
