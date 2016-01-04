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
package com.erinors.ioc.test.integration.case036

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

@Component
class ServiceImpl
{
	@Inject
	@ConfigurationValue("a")
	public int configurationInt

	@Inject
	@ConfigurationValue("a")
	public Integer configurationInteger
}

@Component
class ConfigurationValueProvider
{
	@Provider(parameterizedQualifiers=@ParameterizedQualifier(qualifier=ConfigurationValue, attributeName="value", parameterName="name"))
	def Integer provideConfigurationValue(String name)
	{
		name.charAt(0) - 'a'
	}
}

@Module(components=#[ConfigurationValueProvider, ServiceImpl])
interface TestModule
{
	def ServiceImpl service()
}

class ParameterizedPrimitiveWrapperProviderTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize
		val service = module.service
		assertEquals(0, service.configurationInt)
		assertEquals(0, service.configurationInteger)
	}
}
