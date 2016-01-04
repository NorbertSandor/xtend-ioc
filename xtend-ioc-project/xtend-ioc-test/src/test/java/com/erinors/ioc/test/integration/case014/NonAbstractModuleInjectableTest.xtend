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
package com.erinors.ioc.test.integration.case014

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Injectable
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Optional
import com.google.common.base.Supplier
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test

import static org.junit.Assert.*

interface Service
{
}

@Component
class ServiceImpl implements Service
{
}

@Module(components=#[ServiceImpl])
interface TestModule
{
	def ServiceImpl service()
}

@Injectable(TestModule)
class FirstInjectableClass
{
	@Inject
	public Object i1

	@Inject
	public Service i2

	@Inject
	public ServiceImpl i3

	@Inject
	public Supplier<Object> s1a

	@Inject
	public Supplier<Service> s2a

	@Inject
	public Supplier<ServiceImpl> s3a

	@Inject
	public Supplier<? extends Object> s1b

	@Inject
	public Supplier<? extends Service> s2b

	@Inject
	public Supplier<? extends ServiceImpl> s3b

	@Inject
	public Optional<Object> o1a

	@Inject
	public Optional<Service> o2a

	@Inject
	public Optional<ServiceImpl> o3a

	@Inject
	public Optional<? extends Object> o1b

	@Inject
	public Optional<? extends Service> o2b

	@Inject
	public Optional<? extends ServiceImpl> o3b

}

@Injectable(TestModule)
class SecondInjectableClass
{
	public val Service service

	public val Optional<? extends Service> serviceViaOptional

	@Inject
	new(Service service, Optional<? extends Service> serviceViaOptional)
	{
		this.service = service
		this.serviceViaOptional = serviceViaOptional
	}
}

@Injectable(TestModule)
class ThirdInjectableClass
{
	@Accessors
	val Service service

	@Accessors
	val String value

	new(String value, @Inject
	Service service)
	{
		this.service = service
		this.value = value
	}
}

class NonAbstractModuleInjectableTest
{
	@Test
	def void testSimpleModule()
	{
		val service = TestModule.Peer.initialize.service

		val o1 = new FirstInjectableClass
		assertEquals(service, o1.i1)
		assertEquals(service, o1.i2)
		assertEquals(service, o1.i3)
		assertEquals(service, o1.s1a.get)
		assertEquals(service, o1.s2a.get)
		assertEquals(service, o1.s3a.get)
		assertEquals(service, o1.s1b.get)
		assertEquals(service, o1.s2b.get)
		assertEquals(service, o1.s3b.get)

		val o2 = new SecondInjectableClass
		assertEquals(service, o2.service)
		assertTrue(o2.serviceViaOptional.present)
		assertEquals(service, o2.serviceViaOptional.get)

		val o3 = new ThirdInjectableClass("string")
		assertEquals(service, o3.service)
		assertEquals("string", o3.value)
	}
}
