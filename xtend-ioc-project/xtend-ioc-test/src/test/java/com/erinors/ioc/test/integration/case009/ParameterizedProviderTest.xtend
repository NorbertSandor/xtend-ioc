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
package com.erinors.ioc.test.integration.case009

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.api.Qualifier
import java.lang.annotation.Documented
import java.lang.annotation.Retention
import org.junit.Test

import static org.junit.Assert.*
import com.erinors.ioc.shared.api.ParameterizedQualifier

@Qualifier
@Documented
@Retention(RUNTIME)
annotation ConfigurationValue {
	String value
}

@Component
class ServiceImpl {
	@Inject
	@ConfigurationValue("c")
	public String configurationC
}

@Component
class ConfigurationValueProvider {
	@Provider(parameterizedQualifiers=@ParameterizedQualifier(qualifier=ConfigurationValue, attributeName="value", parameterName="name"))
	def String provideConfigurationValue(String name) {
		'''configuration.«name»'''
	}
}

@Module(components=#[ConfigurationValueProvider, ServiceImpl])
interface TestModule {
	def ServiceImpl service()

	@ConfigurationValue("a")
	def String configurationA()

	@ConfigurationValue("b")
	def String configurationB()
}

class ParameterizedProviderTest {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		assertEquals("configuration.a", module.configurationA)
		assertEquals("configuration.b", module.configurationB)
		assertEquals("configuration.c", module.service.configurationC)
	}
}
