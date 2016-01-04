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
package com.erinors.ioc.test.integration.case020.supplier

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

@Injectable(AbstractModule)
class FirstInjectableClass
{
	@Inject
	public Object i1

	@Inject
	public Service i2

	@Inject
	public Supplier<Object> s1a

	@Inject
	public Supplier<Service> s2a

	@Inject
	public Supplier<? extends Object> s1b

	@Inject
	public Supplier<? extends Service> s2b

	@Inject
	public Optional<Object> o1a

	@Inject
	public Optional<Service> o2a

	@Inject
	public Optional<? extends Object> o1b

	@Inject
	public Optional<? extends Service> o2b

}

@Injectable(AbstractModule)
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

@Injectable(AbstractModule)
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

@Component
class ServiceImpl implements Service
{
}

@Module(isAbstract=true)
interface AbstractModule
{
	def Supplier<Service> service()
}

@Module(components=#[ServiceImpl])
interface TestModule extends AbstractModule
{
}

class AbstractModuleInjectableTest
{
	@Test
	def void testSimpleModule()
	{
		val service = TestModule.Peer.initialize.service

		val o1 = new FirstInjectableClass
		assertEquals(service.get, o1.i1)
		assertEquals(service.get, o1.i2)
		assertEquals(service.get, o1.s1a.get)
		assertEquals(service.get, o1.s2a.get)
		assertEquals(service.get, o1.s1b.get)
		assertEquals(service.get, o1.s2b.get)

		val o2 = new SecondInjectableClass
		assertEquals(service.get, o2.service)
		assertTrue(o2.serviceViaOptional.present)
		assertEquals(service.get, o2.serviceViaOptional.get)

		val o3 = new ThirdInjectableClass("string")
		assertEquals(service.get, o3.service)
		assertEquals("string", o3.value)
	}
}
