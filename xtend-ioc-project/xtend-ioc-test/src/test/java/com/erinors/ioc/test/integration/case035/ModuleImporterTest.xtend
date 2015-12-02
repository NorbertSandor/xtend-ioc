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
package com.erinors.ioc.test.integration.case035

import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.test.integration.HelloService
import com.erinors.ioc.test.integration.HelloServiceImpl
import org.junit.Test

import static org.junit.Assert.*
import com.erinors.ioc.shared.api.ModuleImporter

@Module(components=#[HelloServiceImpl])
interface AnotherModule {
	def HelloService helloService()
}

@ModuleImporter(moduleClassName="com.erinors.ioc.test.integration.case035.AnotherModule")
interface AnotherModuleImporter {
}

@Module(moduleImporters=AnotherModuleImporter)
interface TestModule {
}

class ModuleImporterTest {
	@Test
	def void testSimpleModule() { 
		assertEquals("Hello Jeff!", TestModule.Peer.initialize.helloService.sayHello("Jeff"))
	}
}
