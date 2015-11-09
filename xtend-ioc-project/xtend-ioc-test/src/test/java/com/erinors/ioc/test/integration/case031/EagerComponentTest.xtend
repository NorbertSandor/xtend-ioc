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
package com.erinors.ioc.test.integration.case031

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Eager
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Priority
import javax.annotation.PostConstruct
import org.junit.Test

import static org.junit.Assert.*

@Component
class Collector
{
	val buffer = new StringBuilder

	def void add(String value)
	{
		buffer.append(value)
	}

	def getValue()
	{
		buffer.toString
	}
}

interface ValueProvider
{
	def String getValue()
}

@Component
abstract class AbstractComponent implements ValueProvider
{
	@Inject
	val Collector collector

	@PostConstruct
	def void initialize()
	{
		collector.add(value)
	}
}

@Component
@Eager
@Priority(1)
class Component1 extends AbstractComponent
{
	override getValue()
	{
		"1"
	}
}

@Component
@Eager
@Priority(2)
class Component2 extends AbstractComponent
{
	override getValue()
	{
		"2"
	}
}

@Module(components=#[Collector, Component1, Component2])
interface TestModule
{
	def Collector collector()
}

class EagerComponentTest
{
	@Test
	def void testComponentInheritance()
	{
		val module = TestModule.Peer.initialize
		assertEquals("", module.collector.value)
	}
}
