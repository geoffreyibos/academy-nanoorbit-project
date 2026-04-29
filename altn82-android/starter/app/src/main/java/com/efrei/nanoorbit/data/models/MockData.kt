package com.efrei.nanoorbit.data.models

import java.time.LocalDate
import java.time.LocalDateTime

object MockData {
    val orbites = listOf(
        Orbite(1, TypeOrbite.SSO, 550.0, 97.6, 95.5, 0.001, "Polaire globale - Europe / Arctique"),
        Orbite(2, TypeOrbite.SSO, 700.0, 98.2, 98.8, 0.0008, "Polaire globale - haute latitude"),
        Orbite(3, TypeOrbite.LEO, 400.0, 51.6, 92.6, 0.002, "Equatoriale - zone tropicale")
    )

    val satellites = listOf(
        Satellite("SAT-001", "NanoOrbit-Alpha", StatutSatellite.OPERATIONNEL, FormatCubeSat.U3, 1, "SSO", LocalDate.parse("2022-03-15"), 1.3, 60, 20),
        Satellite("SAT-002", "NanoOrbit-Beta", StatutSatellite.OPERATIONNEL, FormatCubeSat.U3, 1, "SSO", LocalDate.parse("2022-03-15"), 1.3, 60, 20),
        Satellite("SAT-003", "NanoOrbit-Gamma", StatutSatellite.OPERATIONNEL, FormatCubeSat.U6, 2, "SSO", LocalDate.parse("2023-06-10"), 2.0, 84, 40),
        Satellite("SAT-004", "NanoOrbit-Delta", StatutSatellite.EN_VEILLE, FormatCubeSat.U6, 2, "SSO", LocalDate.parse("2023-06-10"), 2.0, 84, 40),
        Satellite("SAT-005", "NanoOrbit-Epsilon", StatutSatellite.DESORBITE, FormatCubeSat.U12, 3, "LEO", LocalDate.parse("2021-11-20"), 4.5, 36, 80)
    )

    val instruments = listOf(
        Instrument("INS-CAM-01", "Camera optique", "PlanetScope-Mini", 3.0, 2.5, 0.4),
        Instrument("INS-IR-01", "Infrarouge", "FLIR-Lepton-3", 160.0, 1.2, 0.15),
        Instrument("INS-AIS-01", "Recepteur AIS", "ShipTrack-V2", null, 0.8, 0.12),
        Instrument("INS-SPEC-01", "Spectrometre", "HyperSpec-Nano", 30.0, 3.1, 0.6)
    )

    val embarquements = listOf(
        Embarquement("SAT-001", "INS-CAM-01", LocalDate.parse("2022-03-15"), "Nominal"),
        Embarquement("SAT-001", "INS-IR-01", LocalDate.parse("2022-03-15"), "Nominal"),
        Embarquement("SAT-002", "INS-CAM-01", LocalDate.parse("2022-03-15"), "Nominal"),
        Embarquement("SAT-003", "INS-CAM-01", LocalDate.parse("2023-06-10"), "Nominal"),
        Embarquement("SAT-003", "INS-SPEC-01", LocalDate.parse("2023-06-10"), "Nominal"),
        Embarquement("SAT-004", "INS-IR-01", LocalDate.parse("2023-06-10"), "Degrade"),
        Embarquement("SAT-005", "INS-AIS-01", LocalDate.parse("2021-11-20"), "Hors service")
    )

    val stations = listOf(
        StationSol("GS-TLS-01", "Toulouse Ground Station", 43.6047, 1.4442, 3.5, "S", 150.0, StatutStation.ACTIVE),
        StationSol("GS-KIR-01", "Kiruna Arctic Station", 67.8557, 20.2253, 5.4, "X", 400.0, StatutStation.ACTIVE),
        StationSol("GS-SGP-01", "Singapore Station", 1.3521, 103.8198, 3.0, "S", 120.0, StatutStation.MAINTENANCE)
    )

    val missions = listOf(
        Mission("MSN-ARC-2023", "ArcticWatch 2023", "Surveillance de la fonte des glaces et dynamique des banquises arctiques", LocalDate.parse("2023-01-01"), StatutMission.ACTIVE, null, "Arctique / Groenland"),
        Mission("MSN-DEF-2022", "DeforestAlert", "Detection et cartographie de la deforestation en temps quasi-reel", LocalDate.parse("2022-06-01"), StatutMission.TERMINEE, LocalDate.parse("2023-05-31"), "Amazonie / Congo"),
        Mission("MSN-COAST-2024", "CoastGuard 2024", "Surveillance de l'evolution du trait de cote et detection d'erosion cotiere", LocalDate.parse("2024-03-01"), StatutMission.ACTIVE, null, "Mediterranee / Atlantique")
    )

    val participations = listOf(
        Participation("SAT-001", "MSN-ARC-2023", "Imageur principal"),
        Participation("SAT-002", "MSN-ARC-2023", "Imageur secondaire"),
        Participation("SAT-003", "MSN-ARC-2023", "Satellite de relais"),
        Participation("SAT-001", "MSN-DEF-2022", "Imageur principal"),
        Participation("SAT-005", "MSN-DEF-2022", "Imageur secondaire"),
        Participation("SAT-003", "MSN-COAST-2024", "Imageur principal"),
        Participation("SAT-004", "MSN-COAST-2024", "Satellite de secours")
    )

    val fenetres = listOf(
        FenetreCom(1, LocalDateTime.parse("2024-01-15T09:14:00"), 420, 82.3, StatutFenetre.REALISEE, "SAT-001", "GS-KIR-01", 1250.0),
        FenetreCom(2, LocalDateTime.parse("2024-01-15T11:52:00"), 310, 67.1, StatutFenetre.REALISEE, "SAT-002", "GS-TLS-01", 890.0),
        FenetreCom(3, LocalDateTime.parse("2024-01-16T08:30:00"), 540, 88.9, StatutFenetre.REALISEE, "SAT-003", "GS-KIR-01", 1680.0),
        FenetreCom(4, LocalDateTime.parse("2026-04-01T14:22:00"), 380, 71.4, StatutFenetre.PLANIFIEE, "SAT-001", "GS-TLS-01", null),
        FenetreCom(5, LocalDateTime.parse("2026-04-01T15:45:00"), 290, 59.8, StatutFenetre.PLANIFIEE, "SAT-003", "GS-TLS-01", null)
    )

    val satelliteIndex = satellites.associateBy(Satellite::idSatellite)
    val orbiteIndex = orbites.associateBy(Orbite::idOrbite)
    val instrumentIndex = instruments.associateBy(Instrument::refInstrument)
    val stationIndex = stations.associateBy(StationSol::codeStation)
    val missionIndex = missions.associateBy(Mission::idMission)

    fun detailForSatellite(idSatellite: String): SatelliteDetail? {
        val satellite = satelliteIndex[idSatellite] ?: return null
        val instrumentsForSatellite = embarquements
            .filter { it.idSatellite == idSatellite }
            .mapNotNull { embarquement ->
                instrumentIndex[embarquement.refInstrument]?.let { SatelliteInstrument(it, embarquement.etatFonctionnement) }
            }

        val missionsForSatellite = participations
            .filter { it.idSatellite == idSatellite }
            .mapNotNull { participation ->
                missionIndex[participation.idMission]?.let { MissionParticipation(it, participation.roleSatellite) }
            }

        return SatelliteDetail(
            satellite = satellite,
            orbite = orbiteIndex[satellite.idOrbite],
            instruments = instrumentsForSatellite,
            missions = missionsForSatellite
        )
    }
}
