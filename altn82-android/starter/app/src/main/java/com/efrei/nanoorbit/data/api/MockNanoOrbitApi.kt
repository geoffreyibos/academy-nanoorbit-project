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
                orbiteType = it.orbiteType,
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

    override suspend fun getSatelliteDetail(satelliteId: String): RemoteSatelliteDetailDto? {
        delay(300)
        val detail = MockData.detailForSatellite(satelliteId) ?: return null
        return RemoteSatelliteDetailDto(
            satellite = RemoteSatelliteDto(
                idSatellite = detail.satellite.idSatellite,
                nomSatellite = detail.satellite.nomSatellite,
                statut = detail.satellite.statut.name,
                formatCubesat = detail.satellite.formatCubesat.label,
                idOrbite = detail.satellite.idOrbite,
                orbiteType = detail.satellite.orbiteType,
                dateLancement = detail.satellite.dateLancement,
                masse = detail.satellite.masse,
                dureeViePrevueMois = detail.satellite.dureeViePrevueMois,
                capaciteBatterie = detail.satellite.capaciteBatterie
            ),
            orbite = detail.orbite?.let {
                RemoteOrbiteDto(
                    idOrbite = it.idOrbite,
                    typeOrbite = it.typeOrbite.name,
                    altitude = it.altitude,
                    inclinaison = it.inclinaison,
                    periodeOrbitale = it.periodeOrbitale,
                    excentricite = it.excentricite,
                    zoneCouverture = it.zoneCouverture
                )
            },
            instruments = detail.instruments.map {
                RemoteSatelliteInstrumentDto(
                    instrument = RemoteInstrumentDto(
                        refInstrument = it.instrument.refInstrument,
                        typeInstrument = it.instrument.typeInstrument,
                        modele = it.instrument.modele,
                        resolution = it.instrument.resolution,
                        consommation = it.instrument.consommation,
                        masse = it.instrument.masse
                    ),
                    etatFonctionnement = it.etatFonctionnement
                )
            },
            missions = detail.missions.map {
                RemoteMissionParticipationDto(
                    mission = RemoteMissionDto(
                        idMission = it.mission.idMission,
                        nomMission = it.mission.nomMission,
                        objectif = it.mission.objectif,
                        dateDebut = it.mission.dateDebut,
                        statutMission = it.mission.statutMission.name,
                        dateFin = it.mission.dateFin,
                        zoneGeoCible = it.mission.zoneGeoCible
                    ),
                    roleSatellite = it.roleSatellite
                )
            }
        )
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

    override suspend fun getStations(): List<RemoteStationDto> {
        delay(300)
        return MockData.stations.map {
            RemoteStationDto(
                codeStation = it.codeStation,
                nomStation = it.nomStation,
                latitude = it.latitude,
                longitude = it.longitude,
                diametreAntenne = it.diametreAntenne,
                bandeFrequence = it.bandeFrequence,
                debitMax = it.debitMax,
                statut = it.statut.name
            )
        }
    }
}
