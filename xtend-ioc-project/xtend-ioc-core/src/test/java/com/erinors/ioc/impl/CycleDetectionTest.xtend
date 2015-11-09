/*
 * #%L
 * xtend-ioc-core
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.impl

import com.erinors.ioc.shared.api.Module
import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.eclipse.xtend.lib.macro.services.Problem.Severity
import org.junit.Test

import static org.junit.Assert.*
import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject

import static extension com.erinors.ioc.impl.AsciiDocUtils.*

//
// Note this file and /xtend-ioc-examples/src/main/java/com/erinors/ioc/examples/docs/avoiddependencygraphcycle/Example.xtend should stay in sync!
//
class CycleDetectionTest
{
	extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

	@Test
	def void testComponentReferenceCycle()
	{
		compilerTester.compile('''
import «Component.name»
import «Inject.name»
import «Module.name»

// tag::Example[]
@Component
class Component1 {
	@Inject // <1>
	Component4 component4

	def boolean someBusinessMethod() {
		component4.anotherBusinessMethod
	}
}

@Component
class Component2 {
	@Inject
	public Component1 component1
}

@Component
class Component3 {
	@Inject
	public Component1 component1

	@Inject
	public Component2 component2
}

@Component
class Component4 {
	@Inject
	public Component3 component3

	def anotherBusinessMethod() {
		true
	}
}

@Module(components=#[Component1, Component2, Component3, Component4])
interface TestModule
{
	def Component1 component1()
}
// end::Example[]
		''', [
			val problems = getProblems(transformationContext.findInterface("TestModule"))

			assertEquals(2, problems.size)

			assertEquals(Severity.ERROR, problems.get(0).severity)
			assertEquals('''
				// tag::ErrorMessage1[]
				Component reference cycle detected: Component1 -> Component4 -> Component3 -> Component1 [E004]
				// end::ErrorMessage1[]
			'''.toString.removeAsciiDocTags, problems.get(0).message)

			assertEquals(Severity.ERROR, problems.get(1).severity)
			assertEquals('''
				// tag::ErrorMessage2[]
				Component reference cycle detected: Component1 -> Component4 -> Component3 -> Component2 -> Component1 [E004]
				// end::ErrorMessage2[]
			'''.toString.removeAsciiDocTags, problems.get(1).message)
		])
	}
}
