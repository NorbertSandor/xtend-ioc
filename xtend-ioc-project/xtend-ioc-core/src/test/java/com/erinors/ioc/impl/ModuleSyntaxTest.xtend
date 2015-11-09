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

class ModuleSyntaxTest
{
	extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

	@Test
	def void testModuleDeclarationShouldBeInterface()
	{
		compilerTester.compile('''
			@«Module.name»
			class TestModule {}
		''', [
			val problems = getProblems(transformationContext.findClass("TestModule"))
			assertEquals(1, problems.size)
			assertEquals(Severity.ERROR, problems.get(0).severity)
			assertEquals('''@«Module.simpleName» is supported only for interface declarations. [E001]'''.toString,
				problems.get(0).message)
		])
	}
}
