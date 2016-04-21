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
package com.erinors.ioc.shared.api

import java.lang.annotation.Documented
import java.lang.annotation.Target

interface Event<T>
{
	def void fire(T event)
}

@Documented
@Target(#[METHOD])
annotation EventObserver
{
	Class<?> eventType = Object
	
	boolean rejectSubtypes = false // TODO rename to ignore*
}
// TODO @EventObserver method should have 1 parameter if eventType is not specified
