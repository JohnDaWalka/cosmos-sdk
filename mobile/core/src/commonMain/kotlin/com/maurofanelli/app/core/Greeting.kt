package com.maurofanelli.app.core

class Greeting {
    private val platform: Platform = getPlatform()

    fun greet(): String {
        return "Hello, ${platform.name}! Welcome to Mar-OS!"
    }
}

expect fun getPlatform(): Platform