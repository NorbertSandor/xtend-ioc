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
package com.erinors.ioc.test.integration.case030

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import org.junit.Test

import static org.junit.Assert.*

interface GenericInterface<T>
{
}

@Component
abstract class ParentComponent<T>
{
	@Inject
	public GenericInterface<T> genericInterface
}

@Component
class GenericInterfaceIntegerImpl implements GenericInterface<Integer>
{
}

@Component
class Child1 extends ParentComponent<Integer>
{
}

@Module(components=#[Child1, GenericInterfaceIntegerImpl])
interface TestModule
{
	def Child1 child1()
}

class GenericComponentInheritanceTest
{
	@Test
	def void testComponentInheritance()
	{
		val module = TestModule.Peer.initialize
		assertNotNull(module.child1.genericInterface)
	}
}
