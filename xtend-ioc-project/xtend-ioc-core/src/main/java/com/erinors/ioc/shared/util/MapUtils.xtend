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
package com.erinors.ioc.shared.util

import com.google.common.collect.ImmutableList
import java.util.List
import java.util.Map
import com.google.common.collect.ImmutableMap

class MapUtils
{
	/**
	 * Convert the iterable of pairs to an immutable {@code Map}.
	 */
	def static <K, V> Map<K, V> pairsToMap(Iterable<Pair<K, V>> keyValuePairs)
	{
		val builder = ImmutableMap.builder
		keyValuePairs.map[key -> value].forEach[builder.put(key, value)]
		builder.build
	}

	/**
	 * Convert a {@code Map} to an immutable list of key-value pairs.
	 */
	def static <K, V> List<Pair<K, V>> mapToPairs(Map<K, V> map)
	{
		val builder = ImmutableList.builder
		// TODO replace with Map.forEach() when GWT supports it
		map.entrySet.forEach[builder.add(Pair.of(key, value))]
		builder.build
	}
}
