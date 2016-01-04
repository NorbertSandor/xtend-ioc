/*
 * #%L
 * xtend-ioc-examples
 * %%
 * Copyright (C) 2015 Norbert Sándor
 * %%
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 * #L%
 */
package com.erinors.ioc.examples.docs.parameterizedproviders2

import com.erinors.ioc.shared.api.Component
import com.erinors.ioc.shared.api.Inject
import com.erinors.ioc.shared.api.Module
import com.erinors.ioc.shared.api.ParameterizedQualifier
import com.erinors.ioc.shared.api.Provider
import com.erinors.ioc.shared.api.Qualifier
import javax.annotation.PostConstruct
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend2.lib.StringConcatenation
import org.junit.Test

import static org.junit.Assert.*

// tag::Example[]
@Qualifier // <1>
annotation LoggerByName {
	String value
}

@FinalFieldsConstructor
class Logger { // <2>
	val String name

	val public log = new StringConcatenation

	def void log(String message) {
		log.append('''[«name»] - «message»''')
		log.newLineIfNotEmpty
	}
}

@Component
class LoggerProvider { // <3>
	@Provider(
	parameterizedQualifiers=@ParameterizedQualifier(qualifier=LoggerByName, //
	attributeName="value", //
	parameterName="loggerName" //
	))
	def Logger loggerProvider(String loggerName) {
		return new Logger(loggerName)
	}
}

@Component // <4>
class TaskExecutor {
	@Inject
	@LoggerByName("initialization")
	public Logger initializationLogger

	@Inject
	@LoggerByName("task")
	public Logger taskLogger

	@PostConstruct
	def void initialize() {
		initializationLogger.log("Started.")
	}

	def void execute(String taskId, Runnable task) {
		taskLogger.log('''Executing task: «taskId»''')
		task.run
	}
}

@Module(components=#[LoggerProvider, TaskExecutor])
interface TestModule {
	def TaskExecutor taskExecutor()
}

class Example {
	@Test
	def void test() {
		val module = TestModule.Peer.initialize
		val taskExecutor = module.taskExecutor

		taskExecutor.execute("task1", [
			// Some heavy work here...
		])
		taskExecutor.execute("task2", [
			// Complex calculation here...
		])

		assertEquals('''
			[initialization] - Started.
		'''.toString, taskExecutor.initializationLogger.log.toString) // <5>
		assertEquals(
		'''
			[task] - Executing task: task1
			[task] - Executing task: task2
		'''.toString, taskExecutor.taskLogger.log.toString)
	}
}
// end::Example[]
