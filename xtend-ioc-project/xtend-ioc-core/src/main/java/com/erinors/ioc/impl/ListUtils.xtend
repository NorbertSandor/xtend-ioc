package com.erinors.ioc.impl

import java.util.List

class ListUtils
{
	def public static <T> removeNullElements(List<T> list)
	{
		return list.filter[it !== null].toList
	}
}