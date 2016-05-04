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
package com.erinors.ioc.test.integration.case015

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.NotRequired
import com.erinors.ioc.shared.api.Provider
import com.google.common.base.Optional
import com.google.common.base.Supplier
import org.junit.Test

import static org.junit.Assert.*

interface NotImplementedInterface {
}

interface ReferencedService
{
}

class ReferencedServiceImpl implements ReferencedService
{
}

@Component
class ProviderImpl
{
	@Provider
	def ReferencedService referencedService()
	{
		new ReferencedServiceImpl
	}
}

@Component
class ServiceImpl
{
	@Inject
	public ReferencedService referencedService

	@Inject
	public Supplier<ReferencedService> referencedServiceSupplier1

	@Inject
	public Supplier<? extends ReferencedService> referencedServiceSupplier2

	@Inject
	public Optional<ReferencedService> referencedServiceOptional1

	@Inject
	public Optional<? extends ReferencedService> referencedServiceOptional2
}

@Module(components=#[ProviderImpl, ServiceImpl])
interface TestModule
{
	def ServiceImpl service()

	def ReferencedService referencedService()

	@NotRequired
	def Supplier<NotImplementedInterface> notImplementedInterfaceSupplier()

	@NotRequired
	def Optional<NotImplementedInterface> notImplementedInterfaceOptional()

	// FIXME ezzel nem fordul, pedig hibát kellene jeleznie, mivel a ReferencedServiceImpl nem érhető el függőségként,
	// csak a ReferencedService interfész: def Supplier<ReferencedServiceImpl> referencedServiceSupplier3()	
}

class ProviderDependencyTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		assertEquals(module.referencedService, module.service.referencedService)
		assertEquals(module.referencedService, module.service.referencedServiceSupplier1.get)
		assertEquals(module.referencedService, module.service.referencedServiceSupplier2.get)
		assertTrue(module.service.referencedServiceOptional1.present)
		assertEquals(module.referencedService, module.service.referencedServiceOptional1.get)
		assertTrue(module.service.referencedServiceOptional2.present)
		assertEquals(module.referencedService, module.service.referencedServiceOptional2.get)
		assertNotNull(module.notImplementedInterfaceSupplier)
		assertNull(module.notImplementedInterfaceSupplier.get)
		assertNotNull(module.notImplementedInterfaceOptional)
		assertFalse(module.notImplementedInterfaceOptional.present)
	}
}
