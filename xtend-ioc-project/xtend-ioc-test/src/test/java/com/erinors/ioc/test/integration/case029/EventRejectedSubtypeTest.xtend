/*
 * #%L
 * xtend-ioc-test
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.test.integration.case029

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Event
import com.erinors.ioc.shared.api.EventObserver
import com.erinors.ioc.shared.api.Module
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test

import static org.junit.Assert.*

class A
{
}

class B extends A
{
}

@Component
class EventObserverComponent1
{
	@Accessors(PUBLIC_GETTER)
	String eventName

	@EventObserver(rejectSubtypes=true)
	def void observeStringEvent(A event)
	{
		eventName = event.class.name
	}
}

@Component
class EventObserverComponent2
{
	@Accessors(PUBLIC_GETTER)
	String eventName

	@EventObserver
	def void observeStringEvent(A event)
	{
		eventName = event.class.name
	}
}

@Module(components=#[EventObserverComponent1, EventObserverComponent2])
interface TestModule
{
	def EventObserverComponent1 eventObserver1()

	def EventObserverComponent2 eventObserver2()

	def Event<A> eventSource()
}

class EventRejectedSubtypeTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize

		assertNull(module.eventObserver1.eventName) // Initial state
		module.eventSource.fire(new B)
		assertNull(module.eventObserver1.eventName) // B is not observed
		module.eventSource.fire(new A)
		assertEquals(A.name, module.eventObserver1.eventName) // A is observed
		module.eventSource.fire(new B)
		assertEquals(A.name, module.eventObserver1.eventName) // B is not observed

		assertNull(module.eventObserver2.eventName) // Initial state
		module.eventSource.fire(new B)
		assertEquals(B.name, module.eventObserver2.eventName) // B is observed
		module.eventSource.fire(new A)
		assertEquals(A.name, module.eventObserver2.eventName) // A is observed
		module.eventSource.fire(new B)
		assertEquals(B.name, module.eventObserver2.eventName) // B is observed
	}
}
