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
package com.erinors.ioc.test.integration.case023

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import java.io.BufferedReader
import java.io.InputStreamReader
import org.junit.Test

import static org.junit.Assert.*
import java.io.File
import java.io.FileInputStream

@Component
class Component1
{
}

@Component
class Component2
{
}

@Component
class Component3
{
	@Inject
	public Component1 component1

	@Inject
	public Component2 component2
}

@Component
class Component4
{
	@Inject
	public Component1 component1

	@Inject
	public Component3 component3
}

@Component
class Component5
{
	@Inject
	public Component6 component6
}

@Component
class Component6
{
}

@Component
class Component7
{
}

@Module(components=#[Component1, Component2, Component3, Component4, Component5, Component6, Component7])
interface TestModule
{
}

class DependencyGraphTest
{
	@Test
	def void testSimpleModule()
	{
		val inputStream = new FileInputStream(new File('''.\target\generated-test-sources\xtend\com\erinors\ioc\test\integration\case023\TestModule.dot'''))
		try
		{
			val reader = new BufferedReader(new InputStreamReader(inputStream, "UTF-8"))
			val lines = newArrayList
			var String line
			while ((line = reader.readLine) != null)
			{
				lines.add(line)
			}

			assertEquals('''
			digraph G {
			  1 [ label="Component1 [1]" ];
			  2 [ label="Component2 [2]" ];
			  3 [ label="Component3 [3]" ];
			  4 [ label="Component4 [4]" ];
			  5 [ label="Component5 [5]" ];
			  6 [ label="Component6 [6]" ];
			  7 [ label="Component7 [7]" ];
			  3 -> 1;
			  3 -> 2;
			  4 -> 1;
			  4 -> 3;
			  5 -> 6;
			}'''.toString, lines.join(System.lineSeparator))
		}
		finally
		{
			inputStream?.close
		}
	}
}
