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
package com.erinors.ioc.test.integration.case021

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Qualifier
import java.util.List
import org.junit.Test

import static org.junit.Assert.*

enum SomeEnum
{
	A,
	B
}

@Qualifier
annotation SubQualifier
{
	SomeEnum enumValue

	int intValue

	String stringValue

	SomeEnum[] enumArray

	int[] intArray

	String[] stringArray
}

@Qualifier
annotation MainQualifier
{
	SubQualifier subQualifier

	SubQualifier[] subQualifiers
}

@Qualifier
annotation AnotherQualifier
{
	Class<?> value
}

interface ComponentInterface
{
}

@Component
@MainQualifier(subQualifier=@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A, B], intArray=#[1,
	2], stringArray=#["A", "B"]), subQualifiers=#[
	@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A, B], intArray=#[1, 2], stringArray=#["A",
		"B"])])
	@AnotherQualifier(String)
	class Component1 implements ComponentInterface
	{
	}

	@Component
	@MainQualifier(subQualifier=@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A, B], intArray=#[1,
		2], stringArray=#["A", "B"]), subQualifiers=#[
		@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A, B], intArray=#[1, 2], stringArray=#["A",
			"B"])])
	class Component2 implements ComponentInterface
	{
	}

	@Module(components=#[Component1, Component2])
	interface TestModule
	{
		def Component1 component1()

		def Component2 component2()

		@AnotherQualifier(String)
		def Object hasAnotherQualifierWithString()

		@AnotherQualifier(String)
		def List<?> listOfHasAnotherQualifierWithString()

		@MainQualifier(subQualifier=@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A,
			B], intArray=#[1, 2], stringArray=#["A", "B"]), subQualifiers=#[
			@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A, B], intArray=#[1, 2], stringArray=#[
				"A", "B"])])
		def List<ComponentInterface> components()

		@MainQualifier(subQualifier=@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A,
			B], intArray=#[1, 2], stringArray=#["A", "B"]), subQualifiers=#[
			@SubQualifier(enumValue=A, intValue=1, stringValue="A", enumArray=#[A, B], intArray=#[1, 2], stringArray=#[
				"A", "B"])])
		@AnotherQualifier(String)
		def Object hasAllQualifiers()
	}

	class CompositeQualifierTest
	{
		@Test
		def void test()
		{
			val module = TestModule.Peer.initialize
			assertEquals(#{module.component1, module.component2}, module.components.toSet)
			assertEquals(#{module.hasAnotherQualifierWithString}, module.listOfHasAnotherQualifierWithString.toSet)
			assertEquals(module.component1, module.hasAllQualifiers)
		}
	}
