// app/src/main/java/com/qw/sutra/network/NetworkMonitor.kt
package com.qw.sutra.network

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import androidx.annotation.RequiresApi

class NetworkMonitor(private val context: Context) {
    private var isNetworkAvailable = false
    private var networkCallback: ((Boolean) -> Unit)? = null

    private val connectivityManager: ConnectivityManager by lazy {
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    fun startMonitoring(callback: (Boolean) -> Unit) {
        this.networkCallback = callback

        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                isNetworkAvailable = true
                networkCallback?.invoke(true)
            }

            override fun onLost(network: Network) {
                isNetworkAvailable = false
                networkCallback?.invoke(false)
            }
        }

        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        connectivityManager.registerNetworkCallback(networkRequest, networkCallback)
    }

    fun isNetworkAvailable(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)
            return capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
        } else {
            @Suppress("DEPRECATION")
            return connectivityManager.activeNetworkInfo?.isConnected == true
        }
    }

    fun stopMonitoring() {
        networkCallback = null
    }
}