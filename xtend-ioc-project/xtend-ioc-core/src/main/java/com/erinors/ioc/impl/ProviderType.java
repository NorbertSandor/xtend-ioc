package com.erinors.ioc.impl;

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

import com.google.common.base.Optional;
import com.google.common.base.Supplier;

enum ProviderType
{
    /**
     * Direct reference.
     */
    DIRECT(null, false),

    /**
     * Reference via {@link Supplier}.
     */
    GUAVA_SUPPLIER(Supplier.class.getName(), false),

    /**
     * Reference via {@link Optional}.
     */
    GUAVA_OPTIONAL(Optional.class.getName(), true);

    private String providerClassName;

    private boolean implicitOptional;

    ProviderType(String providerClassName, boolean implicitOptional)
    {
        this.providerClassName = providerClassName;
        this.implicitOptional = implicitOptional;
    }

    public String getProviderClassName()
    {
        return providerClassName;
    }

    public boolean isByProvider()
    {
        return providerClassName != null;
    }

    public boolean isImplicitOptional()
    {
        return implicitOptional;
    }
}
