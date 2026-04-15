package com.efrei.nanoorbit.data.api

import com.efrei.nanoorbit.data.models.MockData
import kotlinx.coroutines.delay

class MockNanoOrbitApi : NanoOrbitApi {
    override suspend fun getSatellites(): List<RemoteSatelliteDto> {
        delay(500)
        return MockData.satellites.map {
            RemoteSatelliteDto(
                idSatellite = it.idSatellite,
                nomSatellite = it.nomSatellite,
                statut = it.statut.name,
                formatCubesat = it.formatCubesat.label,
                idOrbite = it.idOrbite,
                dateLancement = it.dateLancement,
                masse = it.masse,
                dureeViePrevueMois = it.dureeViePrevueMois,
                capaciteBatterie = it.capaciteBatterie
            )
        }
    }

    override suspend fun getSatelliteInstruments(satelliteId: String): List<RemoteInstrumentDto> {
        delay(500)
        val refs = MockData.embarquements.filter { it.idSatellite == satelliteId }.map { it.refInstrument }.toSet()
        return MockData.instruments
            .filter { it.refInstrument in refs }
            .map {
                RemoteInstrumentDto(
                    refInstrument = it.refInstrument,
                    typeInstrument = it.typeInstrument,
                    modele = it.modele,
                    resolution = it.resolution,
                    consommation = it.consommation,
                    masse = it.masse
                )
            }
    }

    override suspend fun getFenetres(): List<RemoteFenetreDto> {
        delay(500)
        return MockData.fenetres.map {
            RemoteFenetreDto(
                idFenetre = it.idFenetre,
                datetimeDebut = it.datetimeDebut,
                dureeSecondes = it.dureeSecondes,
                elevationMax = it.elevationMax,
                statut = it.statut.name,
                idSatellite = it.idSatellite,
                codeStation = it.codeStation,
                volumeDonnees = it.volumeDonnees
            )
        }
    }
}
