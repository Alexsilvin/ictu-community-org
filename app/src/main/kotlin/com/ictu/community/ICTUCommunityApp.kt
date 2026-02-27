package com.ictu.community

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Application class for ICTU Community.
 * Hilt initialization happens here.
 */
@HiltAndroidApp
class ICTUCommunityApp : Application() {

    override fun onCreate() {
        super.onCreate()
        // TODO: Initialize app-wide components and services
    }
}
