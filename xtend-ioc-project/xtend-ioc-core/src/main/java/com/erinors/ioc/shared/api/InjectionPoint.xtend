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
}

@Data
class FieldInjectionPoint extends DeclaredInjectionPoint
{
	String fieldName

	Class<?> fieldType
}

@Data
class ExecutableInjectionPoint extends DeclaredInjectionPoint
{
}

@Data
class ParameterInjectionPoint extends DeclaredInjectionPoint
{
}
