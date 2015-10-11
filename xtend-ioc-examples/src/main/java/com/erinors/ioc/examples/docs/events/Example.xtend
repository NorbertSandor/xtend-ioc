package com.erinors.ioc.examples.docs.events

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Eager
import com.erinors.ioc.shared.api.Event
import com.erinors.ioc.shared.api.EventObserver
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import javax.annotation.PostConstruct
import org.eclipse.xtend.lib.annotations.Accessors
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
class EventSourceComponent {
	@Inject
	Event<MessageEvent> event // <2>

	@PostConstruct
	def void initialize() {
		fireEvent("a")
	}

	def void fireEvent(String message) {
		event.fire(new MessageEvent(message)) // <3>
	}
}

@Component
class EventObserverComponent {
	@Accessors(PUBLIC_GETTER)
	String messages = ""

	@EventObserver // <4>
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
		val module = TestModule.Instance.initialize // <5>
		val eventSource = module.source
		val observer = module.observer // <6>
		assertEquals("", observer.messages) // <7>
		eventSource.fireEvent("b") // <8>
		assertEquals("b", observer.messages) // <9>
	}
}
// end::Example[]
