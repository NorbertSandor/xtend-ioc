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
package com.erinors.ioc.shared.api

import com.erinors.ioc.impl.ComponentProcessor
import com.erinors.ioc.impl.InjectableProcessor
import com.erinors.ioc.impl.InterceptorProcessor
import com.erinors.ioc.impl.ModuleProcessor
import com.erinors.ioc.shared.impl.ModuleImplementor
import com.erinors.ioc.shared.impl.PrototypeComponentLifecycleManager
import com.erinors.ioc.shared.impl.SingletonComponentLifecycleManager
import com.google.common.base.Supplier
import java.lang.annotation.Annotation
import java.lang.annotation.Documented
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.annotations.Data

/**
 * Indicates that the annotated interface is an <a href="http://norbertsandor.github.io/xtend-ioc/latest/#module-declaration">module</a>.<br>
 * A module is a definition that specifies the components contained by it.
 */
@Documented
@Target(TYPE)
@Active(ModuleProcessor)
annotation Module
{
	/**
	 * Defines whether the module is abstract or non-abstract.
	 * 
	 * @see <a href="http://norbertsandor.github.io/xtend-ioc/latest/#module-abstract">Abstract and non-abstract modules</a>
	 */
	boolean isAbstract = false

	/**
	 * Defines whether the module is singleton or not.
	 * 
	 * @see <a href="http://norbertsandor.github.io/xtend-ioc/latest/#module-singleton">Module lifecycle / Singleton modules</a>
	 */
	boolean singleton = true

	/**
	 * Defines the component classes managed by the module.
	 */
	Class<?>[] components = #[]

	/**
	 * Defines the <a href="http://norbertsandor.github.io/xtend-ioc/latest/#module-declaration">component scan </a> classes.
	 */
	Class<?>[] componentScanClasses = #[]

	/**
	 * Defines the component importer classes.
	 * 
	 * @see ImportComponents
	 */
	Class<?>[] componentImporters = #[]
	
	Class<?>[] moduleImporters = #[]
}

/**
 * Indicates that the annotated type is a <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-importer">component importer</a>.
 */
@Documented
@Target(#[TYPE])
annotation ImportComponents
{
	/**
	 * Component classes to import.
	 */
	Class<?>[] value = #[]
}

/**
 * Identifies <a href="http://norbertsandor.github.io/xtend-ioc/latest/#dependency-injection">injectable</a> constructors, methods and fields of components.
 */
@Documented
@Target(#[CONSTRUCTOR, FIELD, PARAMETER])
annotation Inject
{
}

// TODO document
/**
 * Event fired when the module is initialized.
 */
class ModuleInitializedEvent
{
}

/**
 * Indicates that the annotated class is a <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-class">component class</a>.
 */
@Documented
@Target(#[TYPE]) // TODO support ANNOTATION_TYPE
@Active(ComponentProcessor)
annotation Component
{
	/**
	 * Restricts the type of the annotated component class to this type.<br>
	 * {@code Object} means no restriction.
	 */
	Class<?> type = Object // TODO allow multiple types?
}

/**
 * Indicates that a {@link ComponentLifecycleManager} implementation supports <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-lifecycle-annotations">pre-destroy methods</a>.
 */
annotation SupportsPredestroyCallbacks
{
}

/**
 * There are two usages:
 * <ul>
 * <li>Defines the <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-scope">scope</a> of a component declaration. (The default scope is {@link Singleton}.)</li>
 * <li>Marks an annotation as a scope-annotation.</li>
 * </ul>
 */
@Documented
@Target(#[ANNOTATION_TYPE, TYPE, METHOD])
annotation Scope
{
	Class<? extends ComponentLifecycleManager> value
}

/**
 * Marks a component as <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-scope-singleton">singleton-scoped</a>.
 */
@Scope(SingletonComponentLifecycleManager)
@Documented
@Target(#[ANNOTATION_TYPE, TYPE, METHOD])
annotation Singleton
{
}

/**
 * Marks a component as <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-scope-prototype">prototype-scoped</a>.
 */
@Scope(PrototypeComponentLifecycleManager)
@Documented
@Target(#[ANNOTATION_TYPE, TYPE, METHOD])
annotation Prototype
{
}

// TODO parameterized component cannot be eager
@Documented
@Target(METHOD)
annotation ParameterizedQualifier
{
	Class<? extends Annotation> qualifier

	String attributeName

	String parameterName
}

// TODO error if placed on void method
// TODO allow on field
/**
 * Indicates that the annotated method is a <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-providers">component provider method</a>.
 */
@Documented
@Target(METHOD)
annotation Provider
{
	ParameterizedQualifier[] parameterizedQualifiers = #[]
}

/**
 * An annotation marked with {@code @Qualifier} can be used as <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-qualifiers">component qualifier</a>.
 */
@Documented
@Target(#[ANNOTATION_TYPE])
annotation Qualifier
{
	// TODO support javax.inject.Qualifier
}

interface ComponentLifecycleManager<T> extends Supplier<T>
{
}

// TODO support ANNOTATION_TYPE
@Documented
@Target(#[TYPE])
@Active(InjectableProcessor)
annotation Injectable
{
	Class<? extends ModuleImplementor> value = ModuleImplementor
}

/**
 * Marks a component as <a href="http://norbertsandor.github.io/xtend-ioc/latest/#component-eager">eager</a>.
 */
@Documented
@Target(TYPE)
annotation Eager
{
}

class PriorityConstants
{
	val public static DEFAULT_PRIORITY = 0

	val public static MAX_PRIORITY = Integer.MAX_VALUE
}

@Documented
@Target(TYPE)
annotation Priority
{
	int value = PriorityConstants.DEFAULT_PRIORITY
}

@Documented
@Target(#[TYPE, METHOD, FIELD, PARAMETER])
annotation NotRequired
{
}

@Active(InterceptorProcessor)
@Target(ANNOTATION_TYPE)
annotation Interceptor
{
	Class<? extends InterceptorInvocationHandler> value
}

/**
 * Dynamic properties of an interceptor invocation.
 */
interface InvocationContext
{
	def Object getTarget()

	def Object[] getArguments()

	def Object proceed()

	def Object proceed(Object[] arguments)
}

@Data
abstract class InvocationPointConfiguration
{
	// TODO declaring type, method return type and parameter types 
	
	String methodName
}

interface InterceptorInvocationHandler<T extends InvocationPointConfiguration>
{
	def Object handle(T invocationPointConfiguration, InvocationContext context)
}

annotation MethodReference
{
	Class<?> returnType = Object

	Class<?>[] parameterTypes = #[]
	
	Class<?> sampleDeclaringType = Object
	
	String sampleDeclaredMethodName = ""
}

// TODO @Repeatable(ModuleImporters)
annotation ModuleImporter {
	String moduleClassName
}

annotation ModuleImporters {
	ModuleImporter[] value
}
