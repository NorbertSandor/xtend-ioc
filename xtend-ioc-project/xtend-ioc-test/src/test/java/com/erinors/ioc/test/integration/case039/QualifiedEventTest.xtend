package com.erinors.ioc.test.integration.case039

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Event
import com.erinors.ioc.shared.api.EventObserver
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.Qualifier
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.Test
import org.junit.Assert

@Qualifier
annotation Incoming
{
}

@Qualifier
annotation Outgoing
{
}

class Message
{
}

class NotMessage
{
}

@Component
class MessageObserver
{
	@Accessors(PUBLIC_GETTER)
	int incomingCount

	@Accessors(PUBLIC_GETTER)
	int outgoingCount

	@Accessors(PUBLIC_GETTER)
	int messageCount

	@Accessors(PUBLIC_GETTER)
	int objectCount

	@Accessors(PUBLIC_GETTER)
	int incomingObjectCount

	@EventObserver
	@Incoming
	def void onIncomingMessage(Message message)
	{
		incomingCount++
	}

	@EventObserver
	@Outgoing
	def void onOutgoingMessage(Message message)
	{
		outgoingCount++
	}

	@EventObserver
	def void onAnyMessage(Message message)
	{
		messageCount++
	}

	@EventObserver
	def void onAnyObject(Object object)
	{
		objectCount++
	}

	@EventObserver
	@Incoming
	def void onIncomingObject(Object object)
	{
		incomingObjectCount++
	}
}

@Module(components=#[MessageObserver])
interface TestModule
{
	def MessageObserver messageObserver()

	@Incoming
	def Event<Message> incomingMessageEvent()

	@Outgoing
	def Event<Message> outgoingMessageEvent()

	def Event<NotMessage> notMessageEvent()
}

class QualifiedEventTest
{
	@Test
	def void test()
	{
		val module = TestModule.Peer.initialize

		Assert.assertEquals(0, module.messageObserver.incomingCount)
		Assert.assertEquals(0, module.messageObserver.outgoingCount)
		Assert.assertEquals(0, module.messageObserver.messageCount)
		Assert.assertEquals(0, module.messageObserver.objectCount)
		Assert.assertEquals(0, module.messageObserver.incomingObjectCount)

		module.notMessageEvent.fire(new NotMessage)

		Assert.assertEquals(0, module.messageObserver.incomingCount)
		Assert.assertEquals(0, module.messageObserver.outgoingCount)
		Assert.assertEquals(0, module.messageObserver.messageCount)
		Assert.assertEquals(1, module.messageObserver.objectCount)
		Assert.assertEquals(0, module.messageObserver.incomingObjectCount)

		module.incomingMessageEvent.fire(new Message)

		Assert.assertEquals(1, module.messageObserver.incomingCount)
		Assert.assertEquals(0, module.messageObserver.outgoingCount)
		Assert.assertEquals(1, module.messageObserver.messageCount)
		Assert.assertEquals(2, module.messageObserver.objectCount)
		Assert.assertEquals(1, module.messageObserver.incomingObjectCount)

		module.outgoingMessageEvent.fire(new Message)

		Assert.assertEquals(1, module.messageObserver.incomingCount)
		Assert.assertEquals(1, module.messageObserver.outgoingCount)
		Assert.assertEquals(2, module.messageObserver.messageCount)
		Assert.assertEquals(3, module.messageObserver.objectCount)
		Assert.assertEquals(1, module.messageObserver.incomingObjectCount)
	}
}
