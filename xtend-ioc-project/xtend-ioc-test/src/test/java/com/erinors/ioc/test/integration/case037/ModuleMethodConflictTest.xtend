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
package com.erinors.ioc.test.integration.case037

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Provider
import org.junit.Test

@Component
class ValueProvider
{
	@Provider
	def String value()
	{
		""
	}
}

@Module(isAbstract=true)
interface ModuleA
{
	def String value()
}

@Module(components=ValueProvider)
interface ModuleB
{
	def String value()
}

@Module
interface TestModule extends ModuleA, ModuleB
{
	// This module inherits the same methods from ModuleA and ModuleB.
	// Of course only 1 method should be implemented by the module implementation otherwise a "duplicate method" compilation error would be raised.
}

class ModuleMethodConflictTest
{
	@Test
	def void test()
	{
		TestModule.Peer.initialize
	}
}
