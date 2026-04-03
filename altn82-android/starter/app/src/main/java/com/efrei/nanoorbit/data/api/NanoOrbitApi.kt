package com.efrei.nanoorbit.data.api

import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.Satellite
import retrofit2.http.GET
import retrofit2.http.Path

interface NanoOrbitApi {
    @GET("satellites")
    suspend fun getSatellites(): List<Satellite>

    @GET("satellites/{id}/instruments")
    suspend fun getSatelliteInstruments(@Path("id") satelliteId: String): List<Instrument>

    @GET("fenetres")
    suspend fun getFenetres(): List<FenetreCom>
}
