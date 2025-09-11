package com.maurofanelli.app.core

import kotlin.test.Test
import kotlin.test.assertTrue

class GreetingTest {

    @Test
    fun testGreetingContainsHello() {
        val greeting = Greeting()
        assertTrue(greeting.greet().contains("Hello"), "Greeting should contain 'Hello'")
    }
}