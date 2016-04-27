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
