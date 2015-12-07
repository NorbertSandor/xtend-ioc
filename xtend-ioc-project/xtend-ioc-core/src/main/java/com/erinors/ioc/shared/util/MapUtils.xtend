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

import java.util.Map

class MapUtils
{
	/**
	 * Convert the iterable of pairs to a {@code Map}.
	 */
	def static <K, V> Map<K, V> pairsToMap(Iterable<Pair<K, V>> keyValuePairs)
	{
		val result = newLinkedHashMap
		keyValuePairs.map[key -> value].forEach[result.put(key, value)]
		result
	}
}
