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

import java.lang.annotation.Target

@Target(TYPE)
annotation GwtModule
{
	boolean entryPoint = false
	
	String renameTo = "app"
	
	String[] inherits = #[]
}
