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
package com.erinors.ioc.test.integration.case016

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.google.common.base.Supplier
import java.util.List
import org.junit.Assert
import org.junit.Test

interface Printer<T>
{
	def String print(T o)
}

interface IA
{
}

class A implements IA
{
}

class B
{
}

@Component
class APrinter implements Printer<A>
{
	override print(A o)
	{
		"a"
	}
}

@Component
class BPrinter implements Printer<B>
{
	override print(B o)
	{
		"b"
	}
}

@Module(components=#[APrinter, BPrinter])
interface TestModule
{
	def Printer<A> aPrinter()

	def Printer<? extends IA> iaPrinter()

	def Printer<B> bPrinter()

	def Supplier<Printer<A>> aPrinterSupplier()

	def Supplier<? extends Printer<A>> aPrinterSupplier2()

	def List<? extends Printer<?>> printers()
}

class GenericDependencyTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize

		Assert.assertEquals("a", module.aPrinter.print(new A))
		Assert.assertEquals("b", module.bPrinter.print(new B))

		Assert.assertEquals(2, module.printers.size)
		Assert.assertEquals(module.aPrinter, module.printers.filter(APrinter).head)
		Assert.assertEquals(module.bPrinter, module.printers.filter(BPrinter).head)

		Assert.assertEquals(module.aPrinter, module.aPrinterSupplier.get)
	}
}
