package com.efrei.nanoorbit.data.api

import com.efrei.nanoorbit.BuildConfig
import com.google.gson.GsonBuilder
import com.google.gson.JsonDeserializer
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.time.LocalDate
import java.time.LocalDateTime

object NanoOrbitApiFactory {
    fun create(baseUrl: String = BuildConfig.API_BASE_URL): NanoOrbitApi {
        val gson = GsonBuilder()
            .registerTypeAdapter(LocalDate::class.java, JsonDeserializer { json, _, _ ->
                LocalDate.parse(json.asString)
            })
            .registerTypeAdapter(LocalDateTime::class.java, JsonDeserializer { json, _, _ ->
                LocalDateTime.parse(json.asString)
            })
            .create()

        return Retrofit.Builder()
            .baseUrl(normalizeBaseUrl(baseUrl))
            .client(OkHttpClient.Builder().build())
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
            .create(NanoOrbitApi::class.java)
    }

    private fun normalizeBaseUrl(baseUrl: String): String =
        if (baseUrl.endsWith("/")) baseUrl else "$baseUrl/"
}
