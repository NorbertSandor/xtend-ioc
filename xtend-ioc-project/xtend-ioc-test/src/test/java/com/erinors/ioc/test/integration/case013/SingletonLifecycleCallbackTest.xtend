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
package com.erinors.ioc.test.integration.case013

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Module
import javax.annotation.PostConstruct
import javax.annotation.PreDestroy
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test

import static org.junit.Assert.*

@Component
class ServiceImpl {
	public static String predestroy = ""
	
	@Accessors
	String postconstruct = ""
	
	@PostConstruct
	def void initialize2() {
		postconstruct += "2"
	}
	
	@PostConstruct
	def void initialize1() {
		postconstruct += "1"
	}
	
	@PreDestroy
	def void close2() {
		predestroy += "2"
	}
	
	@PreDestroy
	def void close1() {
		predestroy += "1"
	}
}

@Module(components=#[ServiceImpl])
interface TestModule {
	def ServiceImpl service()
}

class SingletonLifecycleCallbackTest {
	@Test
	def void testSimpleModule() {
		val module = TestModule.Peer.initialize
		assertEquals("21", module.service.postconstruct)
		module.close
		assertEquals("21", ServiceImpl.predestroy)
	}
}
