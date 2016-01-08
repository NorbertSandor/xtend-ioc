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
package com.erinors.ioc.test.integration.case011

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.ParameterizedQualifier
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.api.Qualifier
import java.lang.annotation.Documented
import java.lang.annotation.Retention
import org.junit.Test

import static org.junit.Assert.*

@Qualifier
@Documented
@Retention(RUNTIME)
annotation ConfigurationValue
{
	String value
}

@Qualifier
@Documented
@Retention(RUNTIME)
annotation Environment
{
	String value
}

@Component
class ServiceImpl
{
	@Inject
	@ConfigurationValue("c")
	@Environment("production")
	public String productionConfigurationC

	@Inject
	@ConfigurationValue("c")
	@Environment("development")
	public String developmentConfigurationC
}

@Component
class ConfigurationValueProvider
{
	@Provider(parameterizedQualifiers=#[
		@ParameterizedQualifier(qualifier=ConfigurationValue, attributeName="value", parameterIndex=1),
		@ParameterizedQualifier(qualifier=Environment, attributeName="value", parameterIndex=0)])
	def String provideProductionConfigurationValue(String environment, String name)
	{
		'''«environment».configuration.«name»'''
	}
}

@Module(components=#[ConfigurationValueProvider, ServiceImpl])
interface TestModule
{
	def ServiceImpl service()

	@ConfigurationValue("a")
	@Environment("development")
	def String developmentConfigurationA()

	@ConfigurationValue("b")
	@Environment("production")
	def String productionConfigurationB()
}

class ProviderWithMultipleParameterizedQualifiersTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		assertEquals("development.configuration.a", module.developmentConfigurationA)
		assertEquals("production.configuration.b", module.productionConfigurationB)
		assertEquals("production.configuration.c", module.service.productionConfigurationC)
		assertEquals("development.configuration.c", module.service.developmentConfigurationC)
	}
}
