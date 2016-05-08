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
package com.erinors.ioc.shared.api

import com.google.common.base.MoreObjects
import com.google.common.base.MoreObjects.ToStringHelper
import org.eclipse.xtend.lib.annotations.Data

interface InjectionPoint
{
}

class NoInjectionPoint implements InjectionPoint
{
	val public static INSTANCE = new NoInjectionPoint
}

@Data
class DeclaredInjectionPoint implements InjectionPoint
{
	Class<?> declaringClass

	override String toString()
	{
		createToStringHelper().toString
	}

	protected def ToStringHelper createToStringHelper()
	{
		MoreObjects.toStringHelper(this).add("declaringClass", declaringClass)
	}
}

@Data
class FieldInjectionPoint extends DeclaredInjectionPoint
{
	String fieldName

	Class<?> fieldType

	override toString()
	{
		createToStringHelper().add("fieldName", fieldName).add("fieldType", fieldType).toString
	}
}

@Data
class ExecutableInjectionPoint extends DeclaredInjectionPoint
{
	// Workaround for https://bugs.eclipse.org/bugs/show_bug.cgi?id=458720
	override toString()
	{
		super.toString
	}
}

@Data
class ParameterInjectionPoint extends DeclaredInjectionPoint
{
	// Workaround for https://bugs.eclipse.org/bugs/show_bug.cgi?id=458720
	override toString()
	{
		super.toString
	}
}
