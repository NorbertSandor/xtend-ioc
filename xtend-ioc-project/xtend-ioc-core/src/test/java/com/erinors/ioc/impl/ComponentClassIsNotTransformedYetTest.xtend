/*
 * #%L
 * xtend-ioc-core
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.impl

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.eclipse.xtend.lib.macro.services.Problem.Severity
import org.junit.Ignore
import org.junit.Test

import static org.junit.Assert.*

class ComponentClassIsNotTransformedYetTest
{
	extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

	@Test
	@Ignore
	def void testBadDeclarationOrder()
	{
		compilerTester.compile('''
			import «Module.name»
			import «Component.name»
			
			interface Service
			{
			}
			
			@Module(isAbstract=true)
			interface ParentModule
			{
			}
			
			@Component
			class ServiceImpl implements Service
			{
			}
			
			@Module(components=#[ServiceImpl])
			interface TestModule extends ParentModule
			{
			}
		''', [
			val problems = getProblems(transformationContext.findInterface("TestModule"))
			assertEquals(1, problems.size)
			assertEquals(Severity.ERROR, problems.get(0).severity)
			assertEquals('''Error at ServiceImpl. Component class must be declared before any module that references it.'''.toString,
				problems.get(0).message)
		])
	}
}
