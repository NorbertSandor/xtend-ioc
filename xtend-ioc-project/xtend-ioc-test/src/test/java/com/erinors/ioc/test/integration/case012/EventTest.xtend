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
package com.erinors.ioc.test.integration.case012

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Event
import com.erinors.ioc.shared.api.EventObserver
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test

import static org.junit.Assert.*

@Component
class EventObserverComponent
{
	public static val INCREMENT = 2

	@Accessors(PUBLIC_GETTER)
	String lastStringEvent

	@Accessors(PUBLIC_GETTER)
	int currentValue

	@EventObserver
	def void observeStringEvent(String event)
	{
		lastStringEvent = event
	}

	@EventObserver
	def void observeIntegerEvent1(Integer event)
	{
		currentValue += event
	}

	@EventObserver(eventType = Integer)
	def void observeIntegerEvent2()
	{
		currentValue += INCREMENT
	}
}

@Component
class EventSourceComponent
{
	public static val INCREMENT = 1

	@Inject
	Event<String> stringEvent

	Event<Integer> integerEvent

	@Inject
	new(Event<Integer> integerEvent)
	{
		this.integerEvent = integerEvent
	}

	def void fireStringEvent()
	{
		stringEvent.fire("fire!!!")
	}

	def void fireIntegerEvent()
	{
		integerEvent.fire(INCREMENT)
	}
}

@Module(components=#[EventSourceComponent, EventObserverComponent])
interface TestModule
{
	def EventSourceComponent eventSource()

	def EventObserverComponent eventObserver()

	def Event<Integer> integerEvent()
}

class EventTest
{
	@Test
	def void testEvents()
	{
		val module = TestModule.Peer.initialize

		assertNull(module.eventObserver.lastStringEvent)
		module.eventSource.fireStringEvent
		assertEquals("fire!!!", module.eventObserver.lastStringEvent)

		module.eventSource.fireIntegerEvent
		module.integerEvent.fire(EventSourceComponent.INCREMENT)

		assertEquals(2 * (EventSourceComponent.INCREMENT + EventObserverComponent.INCREMENT),
			module.eventObserver.currentValue)
	}
}
