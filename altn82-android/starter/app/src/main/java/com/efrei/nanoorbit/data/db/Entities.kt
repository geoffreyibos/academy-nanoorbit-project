package com.efrei.nanoorbit.data.db

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.FormatCubeSat
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StatutFenetre
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.data.models.StatutStation
import com.efrei.nanoorbit.data.models.StationSol
import java.time.LocalDate
import java.time.LocalDateTime

@Entity(tableName = "satellites")
data class SatelliteEntity(
    @PrimaryKey val idSatellite: String,
    val nomSatellite: String,
    val statut: String,
    val formatCubesat: String,
    val idOrbite: Int,
    val orbiteType: String?,
    val dateLancement: String?,
    val masse: Double?,
    val dureeViePrevueMois: Int?,
    val capaciteBatterie: Int?,
    val updatedAtMillis: Long
)

@Entity(tableName = "fenetres_com")
data class FenetreEntity(
    @PrimaryKey val idFenetre: Int,
    val datetimeDebut: String,
    val dureeSecondes: Int,
    val elevationMax: Double,
    val statut: String,
    val idSatellite: String,
    val codeStation: String,
    val volumeDonnees: Double?,
    val updatedAtMillis: Long
)

@Entity(tableName = "stations_sol")
data class StationEntity(
    @PrimaryKey val codeStation: String,
    val nomStation: String,
    val latitude: Double,
    val longitude: Double,
    val diametreAntenne: Double?,
    val bandeFrequence: String?,
    val debitMax: Double?,
    val statut: String,
    val updatedAtMillis: Long
)

@Entity(tableName = "satellite_status_overrides")
data class SatelliteStatusOverrideEntity(
    @PrimaryKey val idSatellite: String,
    val statut: String,
    val updatedAtMillis: Long
)

fun SatelliteEntity.toDomain(): Satellite = Satellite(
    idSatellite = idSatellite,
    nomSatellite = nomSatellite,
    statut = StatutSatellite.valueOf(statut),
    formatCubesat = FormatCubeSat.valueOf(formatCubesat),
    idOrbite = idOrbite,
    orbiteType = orbiteType,
    dateLancement = dateLancement?.let(LocalDate::parse),
    masse = masse,
    dureeViePrevueMois = dureeViePrevueMois,
    capaciteBatterie = capaciteBatterie
)

fun Satellite.toEntity(updatedAtMillis: Long): SatelliteEntity = SatelliteEntity(
    idSatellite = idSatellite,
    nomSatellite = nomSatellite,
    statut = statut.name,
    formatCubesat = formatCubesat.name,
    idOrbite = idOrbite,
    orbiteType = orbiteType,
    dateLancement = dateLancement?.toString(),
    masse = masse,
    dureeViePrevueMois = dureeViePrevueMois,
    capaciteBatterie = capaciteBatterie,
    updatedAtMillis = updatedAtMillis
)

fun FenetreEntity.toDomain(): FenetreCom = FenetreCom(
    idFenetre = idFenetre,
    datetimeDebut = LocalDateTime.parse(datetimeDebut),
    dureeSecondes = dureeSecondes,
    elevationMax = elevationMax,
    statut = StatutFenetre.valueOf(statut),
    idSatellite = idSatellite,
    codeStation = codeStation,
    volumeDonnees = volumeDonnees
)

fun FenetreCom.toEntity(updatedAtMillis: Long): FenetreEntity = FenetreEntity(
    idFenetre = idFenetre,
    datetimeDebut = datetimeDebut.toString(),
    dureeSecondes = dureeSecondes,
    elevationMax = elevationMax,
    statut = statut.name,
    idSatellite = idSatellite,
    codeStation = codeStation,
    volumeDonnees = volumeDonnees,
    updatedAtMillis = updatedAtMillis
)

fun StationEntity.toDomain(): StationSol = StationSol(
    codeStation = codeStation,
    nomStation = nomStation,
    latitude = latitude,
    longitude = longitude,
    diametreAntenne = diametreAntenne,
    bandeFrequence = bandeFrequence,
    debitMax = debitMax,
    statut = StatutStation.valueOf(statut)
)

fun StationSol.toEntity(updatedAtMillis: Long): StationEntity = StationEntity(
    codeStation = codeStation,
    nomStation = nomStation,
    latitude = latitude,
    longitude = longitude,
    diametreAntenne = diametreAntenne,
    bandeFrequence = bandeFrequence,
    debitMax = debitMax,
    statut = statut.name,
    updatedAtMillis = updatedAtMillis
)
