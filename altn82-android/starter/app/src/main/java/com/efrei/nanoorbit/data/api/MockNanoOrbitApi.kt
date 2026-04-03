package com.efrei.nanoorbit.data.api

import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.MockData
import com.efrei.nanoorbit.data.models.Satellite
import kotlinx.coroutines.delay

class MockNanoOrbitApi : NanoOrbitApi {
    override suspend fun getSatellites(): List<Satellite> {
        delay(500)
        return MockData.satellites
    }

    override suspend fun getSatelliteInstruments(satelliteId: String): List<Instrument> {
        delay(500)
        val refs = MockData.embarquements.filter { it.idSatellite == satelliteId }.map { it.refInstrument }.toSet()
        return MockData.instruments.filter { it.refInstrument in refs }
    }

    override suspend fun getFenetres(): List<FenetreCom> {
        delay(500)
        return MockData.fenetres
    }
}
