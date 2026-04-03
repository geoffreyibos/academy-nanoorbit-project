package com.efrei.nanoorbit.data.models

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit

// Oracle SATELLITE.statut CHECK mirrored exactly on the Android side.
enum class StatutSatellite { OPERATIONNEL, EN_VEILLE, DEFAILLANT, DESORBITE }

// Oracle SATELLITE.format_cubesat CHECK mirrored on the Android side.
enum class FormatCubeSat(val label: String) { U1("1U"), U3("3U"), U6("6U"), U12("12U") }

enum class TypeOrbite { SSO, LEO, MEO, GEO }

enum class StatutFenetre { PLANIFIEE, REALISEE, ANNULEE }

enum class StatutStation { ACTIVE, MAINTENANCE, HORS_SERVICE }

enum class StatutMission { ACTIVE, TERMINEE, PLANIFIEE }

// Oracle ORBITE
data class Orbite(
    val idOrbite: Int,
    val typeOrbite: TypeOrbite,
    val altitude: Double,
    val inclinaison: Double,
    val periodeOrbitale: Double,
    val excentricite: Double,
    val zoneCouverture: String? = null
)

// Oracle SATELLITE
data class Satellite(
    val idSatellite: String,
    val nomSatellite: String,
    val statut: StatutSatellite,
    val formatCubesat: FormatCubeSat,
    val idOrbite: Int,
    val dateLancement: LocalDate? = null,
    val masse: Double? = null,
    val dureeViePrevueMois: Int? = null,
    val capaciteBatterie: Int? = null
) {
    fun dureeVieRestanteMois(referenceDate: LocalDate = LocalDate.now()): Long? {
        val lancement = dateLancement ?: return null
        val duree = dureeViePrevueMois ?: return null
        val ecoules = ChronoUnit.MONTHS.between(lancement, referenceDate)
        return (duree - ecoules).coerceAtLeast(0)
    }
}

// Oracle INSTRUMENT
data class Instrument(
    val refInstrument: String,
    val typeInstrument: String,
    val modele: String,
    val resolution: Double? = null,
    val consommation: Double? = null,
    val masse: Double? = null
)

// Oracle EMBARQUEMENT
data class Embarquement(
    val idSatellite: String,
    val refInstrument: String,
    val dateIntegration: LocalDate,
    val etatFonctionnement: String
)

// Oracle STATION_SOL
data class StationSol(
    val codeStation: String,
    val nomStation: String,
    val latitude: Double,
    val longitude: Double,
    val diametreAntenne: Double? = null,
    val bandeFrequence: String? = null,
    val debitMax: Double? = null,
    val statut: StatutStation = StatutStation.ACTIVE
)

// Oracle MISSION
data class Mission(
    val idMission: String,
    val nomMission: String,
    val objectif: String,
    val dateDebut: LocalDate,
    val statutMission: StatutMission,
    val dateFin: LocalDate? = null,
    val zoneGeoCible: String? = null
)

// Oracle PARTICIPATION
data class Participation(
    val idSatellite: String,
    val idMission: String,
    val roleSatellite: String
)

// Oracle FENETRE_COM
data class FenetreCom(
    val idFenetre: Int,
    val datetimeDebut: LocalDateTime,
    val dureeSecondes: Int,
    val elevationMax: Double,
    val statut: StatutFenetre,
    val idSatellite: String,
    val codeStation: String,
    val volumeDonnees: Double? = null
)

data class SatelliteInstrument(
    val instrument: Instrument,
    val etatFonctionnement: String
)

data class MissionParticipation(
    val mission: Mission,
    val roleSatellite: String
)

data class SatelliteDetail(
    val satellite: Satellite,
    val orbite: Orbite?,
    val instruments: List<SatelliteInstrument>,
    val missions: List<MissionParticipation>
)

data class RepositoryPayload<T>(
    val data: T,
    val isOffline: Boolean = false,
    val cacheAgeMinutes: Long? = null
)

data class ValidationResult(
    val isValid: Boolean,
    val message: String? = null
)
