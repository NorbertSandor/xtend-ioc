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
package com.erinors.ioc.shared.util

import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.eclipse.xtext.xbase.lib.Procedures.Procedure2

class IterableUtils
{
	/**
	 * Workaround for unimplemented Iterable.forEach() in GWT.
	 */
	def static <T> void foreach(Iterable<T> iterable, Procedure1<? super T> procedure)
	{
		IterableExtensions.forEach(iterable, procedure)
	}

	/**
	 * Workaround for unimplemented Iterable.forEach() in GWT.
	 */
	def static <T> void foreach(Iterable<T> iterable, Procedure2<? super T, ? super Integer> procedure)
	{
		IterableExtensions.forEach(iterable, procedure)
	}
}
