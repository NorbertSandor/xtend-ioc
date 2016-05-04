/*
 * #%L
 * xtend-ioc-core
 * %%
 * Copyright (C) 2015-2016 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.shared.impl

import java.util.Deque
import org.eclipse.xtend.lib.annotations.Data

import static extension com.erinors.ioc.shared.util.IterableUtils.*

interface EventMatcher
{
	def boolean matches(Object eventObject, int[] qualifierIds)
}

interface EventListenerRegistration
{
	def void unregister()
}

interface ModuleEventBus
{
	def EventListenerRegistration registerListener(EventMatcher eventMatcher, (Object)=>void listener)

	def void fire(Object event, int... qualifierIds)
}

class ModuleEventBusImpl implements ModuleEventBus
{
	@Data
	private static class RegisteredEventListener
	{
		int id

		EventMatcher eventMatcher

		(Object)=>void listener
	}

	var nextListenerId = 0

	val eventListeners = <Integer, RegisteredEventListener>newHashMap

	val Deque<Runnable> taskQueue = newLinkedList

	var dispatching = false

	def private runTasks()
	{
		if (!dispatching)
		{
			try
			{
				dispatching = true
				while (!taskQueue.empty)
				{
					taskQueue.poll.run
				}
			}
			finally
			{
				dispatching = false
			}
		}
	}

	override registerListener(EventMatcher eventMatcher, (Object)=>void listener)
	{
		val listenerId = nextListenerId++
		eventListeners.put(listenerId, new RegisteredEventListener(listenerId, eventMatcher, listener))
		return [eventListeners.remove(listenerId)]
	}

	override fire(Object event, int[] qualifierIds)
	{
		eventListeners.values.filter[eventMatcher.matches(event, qualifierIds)].foreach [
			taskQueue.offerLast([
				if (eventListeners.containsKey(id))
				{
					listener.apply(event)
				}
			])
			runTasks
		]
	}
}
