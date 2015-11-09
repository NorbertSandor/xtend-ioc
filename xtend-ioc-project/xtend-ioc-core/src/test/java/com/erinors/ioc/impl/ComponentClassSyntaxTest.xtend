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

import com.erinors.ioc.shared.api.Component
import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.eclipse.xtend.lib.macro.services.Problem.Severity
import org.junit.Test

import static org.junit.Assert.*

class ComponentClassSyntaxTest
{
	extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

	@Test
	def void testComponentClassDeclarationShouldBeClass()
	{
		compilerTester.compile('''
			@«Component.name»
			interface TestComponent {}
		''', [
			val problems = getProblems(transformationContext.findInterface("TestComponent"))
			assertEquals(1, problems.size)
			assertEquals(Severity.ERROR, problems.get(0).severity)
			assertEquals('''@«Component.simpleName» is supported only for class declarations. [E002]'''.toString,
				problems.get(0).message)
		])
	}
}
