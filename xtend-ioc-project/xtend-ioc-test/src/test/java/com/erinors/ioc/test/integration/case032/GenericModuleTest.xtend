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
package com.erinors.ioc.test.integration.case032

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

@Component
class ParentComponent<T>
{
}

@Component
class ComponentInteger extends ParentComponent<Integer>
{
}

@Component
class ComponentString extends ParentComponent<String>
{
}

@Module(singleton = false, isAbstract = true, components=#[ComponentInteger, ComponentString])
interface ParentModule<T>
{
	def List<ParentComponent<?>> parentComponents()
	
	def ComponentInteger componentInteger()
	
	def ComponentString componentString()
	
	def ParentComponent<T> matchingComponent()
}

@Module
interface ModuleInteger extends ParentModule<Integer>
{
}

@Module
interface ModuleString extends ParentModule<String>
{
}

class GenericModuleTest
{
	@Test
	def void testComponentInheritance()
	{
		val moduleInteger = ModuleInteger.Peer.initialize
		assertEquals(#{moduleInteger.componentInteger, moduleInteger.componentString}, moduleInteger.parentComponents.toSet)
		assertEquals(moduleInteger.componentInteger, moduleInteger.matchingComponent)

		val moduleString = ModuleString.Peer.initialize
		assertEquals(#{moduleString.componentInteger, moduleString.componentString}, moduleString.parentComponents.toSet)
		assertEquals(moduleString.componentString, moduleString.matchingComponent)
	}
}
