/*
 * #%L
 * xtend-ioc-examples
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.examples.docs.events

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Eager
import com.erinors.ioc.shared.api.Event
import com.erinors.ioc.shared.api.EventObserver
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.ModuleInitializedEvent
import com.erinors.ioc.shared.api.Priority
import javax.annotation.PostConstruct
import org.eclipse.xtend.lib.annotations.Data
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Data // <1>
class MessageEvent {
	String message
}

@Component
@Eager
@Priority(1) // <2>
class EventSourceComponent {
	@Inject
	Event<MessageEvent> event // <3>

	@PostConstruct
	def void componentInitialized() {
		fireEvent("C") // <4>
	}

	@EventObserver(eventType=ModuleInitializedEvent) // <5>
	def void moduleInitialize() {
		fireEvent("M") // <6>
	}
	
	def void fireEvent(String message) {
		event.fire(new MessageEvent(message)) // <7>
	}
}

@Component
@Eager
@Priority(0) // <8>
class EventObserverComponent {
	val messages = newArrayList

	def getMessages() {
		messages.join(",")
	}

	@EventObserver // <9>
	def void observe(MessageEvent event) {
		messages += event.message
	}
}

@Module(components=#[EventSourceComponent, EventObserverComponent])
interface TestModule {
	def EventSourceComponent source()

	def EventObserverComponent observer()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize // <10>
		assertEquals("M", module.observer.messages) // <11>
		module.source.fireEvent("1") // <12>
		assertEquals("M,1", module.observer.messages) // <13>
	}
}
// end::Example[]
