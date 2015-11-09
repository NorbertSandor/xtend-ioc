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
package com.erinors.ioc.test.integration.case003

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.test.integration.HelloService
import com.erinors.ioc.test.integration.HelloServiceImpl
import com.google.common.base.Supplier
import org.junit.Assert
import org.junit.Test
import com.erinors.ioc.shared.api.NotRequired

interface NotImplementedInterface
{
}

@Component
class ComponentWithInjectedFields
{
	@javax.inject.Inject
	public HelloService helloService1

	@Inject
	public Supplier<HelloService> helloService2

	@Inject
	public Supplier<? extends HelloService> helloService3

	@Inject
	public com.google.common.base.Optional<HelloService> helloService4

	@Inject
	public com.google.common.base.Optional<? extends HelloService> helloService5

	@Inject
	@NotRequired
	public NotImplementedInterface unresolved1

	@Inject
	@NotRequired
	public Supplier<NotImplementedInterface> unresolved2

	@Inject
	@NotRequired
	public Supplier<? extends NotImplementedInterface> unresolved3

	@Inject
	public com.google.common.base.Optional<NotImplementedInterface> unresolved4

	@Inject
	public com.google.common.base.Optional<? extends NotImplementedInterface> unresolved5
}

@Component
class ComponentWithInjectedConstructor
{
	public HelloService helloService1

	public Supplier<HelloService> helloService2

	public Supplier<? extends HelloService> helloService3

	public com.google.common.base.Optional<HelloService> helloService4

	public com.google.common.base.Optional<? extends HelloService> helloService5

	public NotImplementedInterface unresolved1

	public Supplier<NotImplementedInterface> unresolved2

	public Supplier<? extends NotImplementedInterface> unresolved3

	public com.google.common.base.Optional<NotImplementedInterface> unresolved4

	public com.google.common.base.Optional<? extends NotImplementedInterface> unresolved5

	@Inject
	new(
		HelloService helloService1,
		Supplier<HelloService> helloService2,
		Supplier<? extends HelloService> helloService3,
		com.google.common.base.Optional<HelloService> helloService4,
		com.google.common.base.Optional<? extends HelloService> helloService5,
		@NotRequired
		NotImplementedInterface unresolved1,
		@NotRequired
		Supplier<NotImplementedInterface> unresolved2,
		@NotRequired
		Supplier<? extends NotImplementedInterface> unresolved3,
		com.google.common.base.Optional<NotImplementedInterface> unresolved4,
		com.google.common.base.Optional<? extends NotImplementedInterface> unresolved5
	)
	{
		this.helloService1 = helloService1
		this.helloService2 = helloService2
		this.helloService3 = helloService3
		this.helloService4 = helloService4
		this.helloService5 = helloService5
		this.unresolved1 = unresolved1
		this.unresolved2 = unresolved2
		this.unresolved3 = unresolved3
		this.unresolved4 = unresolved4
		this.unresolved5 = unresolved5
	}
}

@Module(components=#[HelloServiceImpl, ComponentWithInjectedConstructor, ComponentWithInjectedFields])
interface TestModule
{
	def ComponentWithInjectedConstructor componentWithInjectedConstructor()

	def ComponentWithInjectedFields componentWithInjectedFields()

	def HelloService helloService1()

	def Supplier<HelloService> helloService2()

	def Supplier<? extends HelloService> helloService3()

	def com.google.common.base.Optional<HelloService> helloService4()

	def com.google.common.base.Optional<? extends HelloService> helloService5()

	@NotRequired
	def NotImplementedInterface unresolved1()

	@NotRequired
	def Supplier<NotImplementedInterface> unresolved2()

	@NotRequired
	def Supplier<? extends NotImplementedInterface> unresolved3()

	def com.google.common.base.Optional<NotImplementedInterface> unresolved4()

	def com.google.common.base.Optional<? extends NotImplementedInterface> unresolved5()
}

class ComponentReferenceTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize

		val helloService = module.helloService1
		val componentWithInjectedFields = module.componentWithInjectedFields
		val componentWithInjectedConstructor = module.componentWithInjectedConstructor

		Assert.assertEquals(helloService, componentWithInjectedFields.helloService1)
		Assert.assertEquals(helloService, componentWithInjectedConstructor.helloService1)

		Assert.assertEquals(helloService, module.helloService2.get)
		Assert.assertEquals(helloService, componentWithInjectedFields.helloService2.get)
		Assert.assertEquals(helloService, componentWithInjectedConstructor.helloService2.get)

		Assert.assertEquals(helloService, module.helloService3.get)
		Assert.assertEquals(helloService, componentWithInjectedFields.helloService3.get)
		Assert.assertEquals(helloService, componentWithInjectedConstructor.helloService3.get)

		Assert.assertTrue(module.helloService4.present)
		Assert.assertEquals(helloService, module.helloService4.get)
		Assert.assertTrue(componentWithInjectedFields.helloService4.present)
		Assert.assertEquals(helloService, componentWithInjectedFields.helloService4.get)
		Assert.assertTrue(componentWithInjectedConstructor.helloService4.present)
		Assert.assertEquals(helloService, componentWithInjectedConstructor.helloService4.get)

		Assert.assertTrue(module.helloService5.present)
		Assert.assertEquals(helloService, module.helloService5.get)
		Assert.assertTrue(componentWithInjectedFields.helloService5.present)
		Assert.assertEquals(helloService, componentWithInjectedFields.helloService5.get)
		Assert.assertTrue(componentWithInjectedConstructor.helloService5.present)
		Assert.assertEquals(helloService, componentWithInjectedConstructor.helloService5.get)

		Assert.assertNull(module.unresolved1)
		Assert.assertNull(componentWithInjectedFields.unresolved1)
		Assert.assertNull(componentWithInjectedConstructor.unresolved1)

		Assert.assertNull(module.unresolved2.get)
		Assert.assertNull(componentWithInjectedFields.unresolved2.get)
		Assert.assertNull(componentWithInjectedConstructor.unresolved2.get)

		Assert.assertNull(module.unresolved3.get)
		Assert.assertNull(componentWithInjectedFields.unresolved3.get)
		Assert.assertNull(componentWithInjectedConstructor.unresolved3.get)

		Assert.assertFalse(module.unresolved4.present)
		Assert.assertFalse(componentWithInjectedFields.unresolved4.present)
		Assert.assertFalse(componentWithInjectedConstructor.unresolved4.present)

		Assert.assertFalse(module.unresolved5.present)
		Assert.assertFalse(componentWithInjectedFields.unresolved5.present)
		Assert.assertFalse(componentWithInjectedConstructor.unresolved5.present)
	}
}
