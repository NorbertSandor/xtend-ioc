package com.erinors.ioc.shared.api

import java.lang.annotation.Target

@Target(TYPE)
annotation GwtModule
{
	boolean entryPoint = false
	
	String[] inherits = #[]
}
