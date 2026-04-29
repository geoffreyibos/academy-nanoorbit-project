package com.efrei.nanoorbit.data.api

import retrofit2.http.GET
import retrofit2.http.Path

interface NanoOrbitApi {
    @GET("satellites")
    suspend fun getSatellites(): List<RemoteSatelliteDto>

    @GET("satellites/{id}/instruments")
    suspend fun getSatelliteInstruments(@Path("id") satelliteId: String): List<RemoteInstrumentDto>

    @GET("satellites/{id}/detail")
    suspend fun getSatelliteDetail(@Path("id") satelliteId: String): RemoteSatelliteDetailDto?

    @GET("fenetres")
    suspend fun getFenetres(): List<RemoteFenetreDto>

    @GET("stations")
    suspend fun getStations(): List<RemoteStationDto>
}
