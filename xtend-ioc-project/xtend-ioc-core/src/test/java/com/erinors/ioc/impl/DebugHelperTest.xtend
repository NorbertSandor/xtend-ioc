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
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Injectable
import com.erinors.ioc.shared.api.Interceptor
import com.erinors.ioc.shared.api.InterceptorInvocationHandler
import com.erinors.ioc.shared.api.InvocationContext
import com.erinors.ioc.shared.api.MethodReference
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Prototype
import com.erinors.ioc.shared.api.Qualifier
import com.erinors.ioc.shared.impl.ModuleImplementor
import com.erinors.ioc.shared.impl.ModuleInstance
import com.google.common.base.Optional
import com.google.common.base.Supplier
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.core.compiler.batch.XtendCompilerTester
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test
import com.erinors.ioc.shared.api.ParameterizedQualifier
import java.lang.annotation.Documented
import java.lang.annotation.Retention
import com.erinors.ioc.shared.api.Provider
import org.junit.Ignore

class DebugHelperTest
{
	extension XtendCompilerTester compilerTester = XtendCompilerTester.newXtendCompilerTester(class.classLoader)

	@Test
//	@Ignore
	def void test()
	{
		'''
import «Component.name»
import «Inject.name»
import «Module.name»
import «Supplier.name»
import «ModuleImplementor.name»
import «ModuleInstance.name»
import «Injectable.name»
import «Qualifier.name»
import «Provider.name»
import «List.name»
import «Prototype.name»
import «Interceptor.name»
import «InterceptorInvocationHandler.name»
import «InvocationContext.name»
import «Optional.name»
import «Accessors.name»
import «MethodReference.name»
import «Target.name»
import «Documented.name»
import «Retention.name»
import «ParameterizedQualifier.name»

@Qualifier
@Documented
annotation ConfigurationValue {
	Class<?> value
}

@Component
class ServiceImpl {
	@Inject
	@ConfigurationValue(Integer)
	public String configurationC
}

@Component
class ConfigurationValueProvider {
	@Provider(parameterizedQualifiers=@ParameterizedQualifier(qualifier=ConfigurationValue, attributeName="value", parameterName="clazz"))
	def String provideConfigurationValue(Class<?> clazz) {
		"configuration." + clazz.name
	}
}

@Module(components=#[ConfigurationValueProvider, ServiceImpl])
interface TestModule {
	// def ServiceImpl service()
}
'''.compile [
			System.out.println(allProblems.map[message])
			System.out.println(singleGeneratedCode)
		]
	}
}
