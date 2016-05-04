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
package com.erinors.ioc.test.integration.case038

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.NotRequired
import com.erinors.ioc.shared.api.Provider
import com.google.common.base.Supplier
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test

import static org.junit.Assert.*
import com.google.common.base.Optional

@Component
class ProviderReturningNull
{
	@Provider
	def String provideString()
	{
		null
	}
}

@Component
@Accessors
class SomeComponent
{
	@Inject
	@NotRequired
	val String s1

	@Inject
	val Supplier<String> s2

	@Inject
	@NotRequired
	val Supplier<String> s3

	@Inject
	val Optional<String> s4
}

@Module(components=#[SomeComponent, ProviderReturningNull])
interface TestModule
{
	def SomeComponent someComponent()
}

class ProviderReturningNullTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize

		assertNull(module.someComponent.s1)
		assertNull(module.someComponent.s2.get)
		assertNull(module.someComponent.s3.get)
		assertFalse(module.someComponent.s4.present)
	}
}
