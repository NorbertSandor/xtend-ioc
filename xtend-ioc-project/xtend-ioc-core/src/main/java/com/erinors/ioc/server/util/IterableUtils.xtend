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
package com.erinors.ioc.server.util

import com.google.common.collect.Iterables

class IterableUtils
{
	/**
	 * Cast all elements of the source iterable to the given type.
	 */
	def static <T> Iterable<T> castElements(Iterable<?> fromIterable, Class<T> targetType)
	{
		Iterables.transform(fromIterable, [targetType.cast(it)])
	}
}
