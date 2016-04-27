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
package ${package}

import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Component

@Component
class HelloService
{
	def String sayHello(String to)
	'''Hello «to»!'''
}

@Module(components=#[HelloService])
interface ApplicationModule
{
	def HelloService helloService()
}

class Application
{
	def static void main(String[] args)
	{
		val module = ApplicationModule.Peer.initialize
		println(module.helloService.sayHello("World"))
	}
}
