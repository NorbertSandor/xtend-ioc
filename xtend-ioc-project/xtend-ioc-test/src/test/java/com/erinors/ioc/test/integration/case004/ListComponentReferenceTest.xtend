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
package com.erinors.ioc.test.integration.case004

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.NotRequired
import com.erinors.ioc.test.integration.HelloService
import com.google.common.base.Optional
import com.google.common.base.Supplier
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

interface NotImplementedInterface
{
}

@Component
class EnglishHelloServiceImpl implements HelloService
{
	override sayHello(String name)
	{
		'''Hello «name»!'''
	}
}

@Component
class HungarianHelloServiceImpl implements HelloService
{
	override sayHello(String name)
	{
		'''Szia «name»!'''
	}
}

@Component
class ComponentWithInjectedFields
{
	//
	// Resolved
	//
	// List of direct component references
	@Inject
	public List<HelloService> helloServices1

	@Inject
	public List<? extends HelloService> helloServices2

	// List of suppliers
	@Inject
	public List<Supplier<HelloService>> helloServices3

	@Inject
	public List<Supplier<? extends HelloService>> helloServices4

	@Inject
	public List<? extends Supplier<HelloService>> helloServices5

	@Inject
	public List<? extends Supplier<? extends HelloService>> helloServices6

	//
	// Unresolved
	//
	// List of direct component references
	@Inject
	@NotRequired
	public List<NotImplementedInterface> unresolved1

	@Inject
	@NotRequired
	public List<? extends NotImplementedInterface> unresolved2

	// List of suppliers
	@Inject
	@NotRequired
	public List<Supplier<NotImplementedInterface>> unresolved3

	@Inject
	@NotRequired
	public List<Supplier<? extends NotImplementedInterface>> unresolved4

	@Inject
	@NotRequired
	public List<? extends Supplier<NotImplementedInterface>> unresolved5

	@Inject
	@NotRequired
	public List<? extends Supplier<? extends NotImplementedInterface>> unresolved6
}

@Component
class ComponentWithInjectedConstructor
{
	//
	// Resolved
	//
	// List of direct component references
	public List<HelloService> helloServices1

	public List<? extends HelloService> helloServices2

	// List of suppliers
	public List<Supplier<HelloService>> helloServices3

	public List<Supplier<? extends HelloService>> helloServices4

	public List<? extends Supplier<HelloService>> helloServices5

	public List<? extends Supplier<? extends HelloService>> helloServices6

	// List of optionals
	public List<Optional<HelloService>> helloServices7

	public List<Optional<? extends HelloService>> helloServices8

	public List<? extends Optional<HelloService>> helloServices9

	public List<? extends Optional<? extends HelloService>> helloServices10

	//
	// Unresolved
	//
	// List of direct component references
	public List<NotImplementedInterface> unresolved1

	public List<? extends NotImplementedInterface> unresolved2

	// List of suppliers
	public List<Supplier<NotImplementedInterface>> unresolved3

	public List<Supplier<? extends NotImplementedInterface>> unresolved4

	public List<? extends Supplier<NotImplementedInterface>> unresolved5

	public List<? extends Supplier<? extends NotImplementedInterface>> unresolved6

	// List of optionals
	public List<Optional<NotImplementedInterface>> unresolved7

	public List<Optional<? extends NotImplementedInterface>> unresolved8

	public List<? extends Optional<NotImplementedInterface>> unresolved9

	public List<? extends Optional<? extends NotImplementedInterface>> unresolved10

	@Inject
	new(
		List<HelloService> helloServices1,
		List<? extends HelloService> helloServices2,
		List<Supplier<HelloService>> helloServices3,
		List<Supplier<? extends HelloService>> helloServices4,
		List<? extends Supplier<HelloService>> helloServices5,
		List<? extends Supplier<? extends HelloService>> helloServices6,
		@NotRequired
		List<NotImplementedInterface> unresolved1,
		@NotRequired
		List<? extends NotImplementedInterface> unresolved2,
		@NotRequired
		List<Supplier<NotImplementedInterface>> unresolved3,
		@NotRequired
		List<Supplier<? extends NotImplementedInterface>> unresolved4,
		@NotRequired
		List<? extends Supplier<NotImplementedInterface>> unresolved5,
		@NotRequired
		List<? extends Supplier<? extends NotImplementedInterface>> unresolved6
	)
	{
		this.helloServices1 = helloServices1
		this.helloServices2 = helloServices2
		this.helloServices3 = helloServices3
		this.helloServices4 = helloServices4
		this.helloServices5 = helloServices5
		this.helloServices6 = helloServices6
		this.unresolved1 = unresolved1
		this.unresolved2 = unresolved2
		this.unresolved3 = unresolved3
		this.unresolved4 = unresolved4
		this.unresolved5 = unresolved5
		this.unresolved6 = unresolved6
	}
}

@Module(components=#[EnglishHelloServiceImpl, HungarianHelloServiceImpl, ComponentWithInjectedConstructor,
	ComponentWithInjectedFields])
interface TestModule
{
	def ComponentWithInjectedConstructor componentWithInjectedConstructor()

	def ComponentWithInjectedFields componentWithInjectedFields()

	//
	// Resolved
	//
	// List of direct component references
	def List<HelloService> helloServices1()

	def List<? extends HelloService> helloServices2()

	// List of suppliers
	def List<Supplier<HelloService>> helloServices3()

	def List<Supplier<? extends HelloService>> helloServices4()

	def List<? extends Supplier<HelloService>> helloServices5()

	def List<? extends Supplier<? extends HelloService>> helloServices6()

	//
	// Unresolved
	//
	// List of direct component references
	@NotRequired
	def List<NotImplementedInterface> unresolved1()

	@NotRequired
	def List<? extends NotImplementedInterface> unresolved2()

	// List of suppliers
	@NotRequired
	def List<Supplier<NotImplementedInterface>> unresolved3()

	@NotRequired
	def List<Supplier<? extends NotImplementedInterface>> unresolved4()

	@NotRequired
	def List<? extends Supplier<NotImplementedInterface>> unresolved5()

	@NotRequired
	def List<? extends Supplier<? extends NotImplementedInterface>> unresolved6()
}

class ListComponentReferenceTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize

		assertEquals("Hello Jeff!", module.helloServices1.filter(EnglishHelloServiceImpl).head.sayHello("Jeff"))
		assertEquals("Szia Jeff!", module.helloServices1.filter(HungarianHelloServiceImpl).head.sayHello("Jeff"))

		val helloServices = module.helloServices1
		val componentWithInjectedFields = module.componentWithInjectedFields
		val componentWithInjectedConstructor = module.componentWithInjectedConstructor

		assertEquals(helloServices, module.helloServices1)
		assertEquals(helloServices, componentWithInjectedFields.helloServices1)
		assertEquals(helloServices, componentWithInjectedConstructor.helloServices1)

		assertEquals(helloServices, module.helloServices2)
		assertEquals(helloServices, componentWithInjectedFields.helloServices2)
		assertEquals(helloServices, componentWithInjectedConstructor.helloServices2)

		assertEquals(helloServices, module.helloServices3.map[get])
		assertEquals(helloServices, componentWithInjectedFields.helloServices3.map[get])
		assertEquals(helloServices, componentWithInjectedConstructor.helloServices3.map[get])

		assertEquals(helloServices, module.helloServices4.map[get])
		assertEquals(helloServices, componentWithInjectedFields.helloServices4.map[get])
		assertEquals(helloServices, componentWithInjectedConstructor.helloServices4.map[get])

		assertEquals(helloServices, module.helloServices5.map[get])
		assertEquals(helloServices, componentWithInjectedFields.helloServices5.map[get])
		assertEquals(helloServices, componentWithInjectedConstructor.helloServices5.map[get])

		assertEquals(helloServices, module.helloServices6.map[get])
		assertEquals(helloServices, componentWithInjectedFields.helloServices6.map[get])
		assertEquals(helloServices, componentWithInjectedConstructor.helloServices6.map[get])

		assertTrue(module.unresolved1.empty)
		assertTrue(componentWithInjectedFields.unresolved1.empty)
		assertTrue(componentWithInjectedFields.unresolved1.empty)

		assertTrue(module.unresolved2.empty)
		assertTrue(componentWithInjectedFields.unresolved2.empty)
		assertTrue(componentWithInjectedFields.unresolved2.empty)

		assertTrue(module.unresolved3.empty)
		assertTrue(componentWithInjectedFields.unresolved3.empty)
		assertTrue(componentWithInjectedFields.unresolved3.empty)

		assertTrue(module.unresolved4.empty)
		assertTrue(componentWithInjectedFields.unresolved4.empty)
		assertTrue(componentWithInjectedFields.unresolved4.empty)

		assertTrue(module.unresolved5.empty)
		assertTrue(componentWithInjectedFields.unresolved5.empty)
		assertTrue(componentWithInjectedFields.unresolved5.empty)

		assertTrue(module.unresolved6.empty)
		assertTrue(componentWithInjectedFields.unresolved6.empty)
		assertTrue(componentWithInjectedFields.unresolved6.empty)
	}
}
