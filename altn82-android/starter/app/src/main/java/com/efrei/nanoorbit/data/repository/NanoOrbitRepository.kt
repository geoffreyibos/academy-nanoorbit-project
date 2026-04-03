package com.efrei.nanoorbit.data.repository

import com.efrei.nanoorbit.data.api.MockNanoOrbitApi
import com.efrei.nanoorbit.data.api.NanoOrbitApi
import com.efrei.nanoorbit.data.db.FenetreDao
import com.efrei.nanoorbit.data.db.SatelliteDao
import com.efrei.nanoorbit.data.db.toDomain
import com.efrei.nanoorbit.data.db.toEntity
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.MockData
import com.efrei.nanoorbit.data.models.RepositoryPayload
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.SatelliteDetail
import com.efrei.nanoorbit.data.models.StationSol
import com.efrei.nanoorbit.data.models.ValidationResult
import java.time.Duration
import java.time.LocalDateTime

class NanoOrbitRepository(
    private val satelliteDao: SatelliteDao,
    private val fenetreDao: FenetreDao,
    private val api: NanoOrbitApi = MockNanoOrbitApi()
) {
    suspend fun getSatellitesCacheFirst(): RepositoryPayload<List<Satellite>> {
        val cached = satelliteDao.getAll()
        if (cached.isNotEmpty()) {
            val latestUpdate = cached.maxOf { it.updatedAtMillis }
            return RepositoryPayload(
                data = cached.map { it.toDomain() },
                isOffline = true,
                cacheAgeMinutes = Duration.between(
                    java.time.Instant.ofEpochMilli(latestUpdate),
                    java.time.Instant.now()
                ).toMinutes()
            )
        }
        return refreshSatellites()
    }

    suspend fun refreshSatellites(): RepositoryPayload<List<Satellite>> {
        val remote = api.getSatellites()
        val updatedAt = System.currentTimeMillis()
        satelliteDao.upsertAll(remote.map { it.toEntity(updatedAt) })
        return RepositoryPayload(remote, isOffline = false, cacheAgeMinutes = 0L)
    }

    suspend fun getFenetresCacheFirst(): RepositoryPayload<List<FenetreCom>> {
        val cached = fenetreDao.getAll()
        if (cached.isNotEmpty()) {
            val latestUpdate = cached.maxOf { it.updatedAtMillis }
            return RepositoryPayload(
                data = cached.map { it.toDomain() },
                isOffline = true,
                cacheAgeMinutes = Duration.between(
                    java.time.Instant.ofEpochMilli(latestUpdate),
                    java.time.Instant.now()
                ).toMinutes()
            )
        }
        return refreshFenetres()
    }

    suspend fun refreshFenetres(): RepositoryPayload<List<FenetreCom>> {
        val remote = api.getFenetres()
        val upcoming = remote.filter {
            Duration.between(LocalDateTime.now(), it.datetimeDebut).toDays() <= 7 || it.datetimeDebut.isBefore(LocalDateTime.now())
        }
        val updatedAt = System.currentTimeMillis()
        fenetreDao.upsertAll(upcoming.map { it.toEntity(updatedAt) })
        return RepositoryPayload(upcoming, isOffline = false, cacheAgeMinutes = 0L)
    }

    fun getStations(): List<StationSol> = MockData.stations

    fun getSatelliteDetail(satelliteId: String): SatelliteDetail? = MockData.detailForSatellite(satelliteId)

    fun getOrbiteTypeForSatellite(idSatellite: String): String {
        val satellite = MockData.satelliteIndex[idSatellite] ?: return ""
        return MockData.orbiteIndex[satellite.idOrbite]?.typeOrbite?.name.orEmpty()
    }

    // ALTN83 Phase 1 Q3 mirror: the cache-first strategy lets the app keep planning and consulting
    // local data even if the central Oracle service is unavailable.
    fun formatCacheAge(cacheAgeMinutes: Long?): String? = cacheAgeMinutes?.let { "Mis a jour il y a $it min" }

    fun validateFenetreCreation(
        satelliteId: String,
        stationCode: String,
        dureeSecondes: Int
    ): ValidationResult {
        if (dureeSecondes !in 1..900) {
            return ValidationResult(false, "Duree invalide : entre 1 et 900 secondes")
        }

        val satellite = MockData.satelliteIndex[satelliteId]
        if (satellite?.statut?.name == "DESORBITE") {
            return ValidationResult(false, "Fenetre refusee : satellite desorbite")
        }

        val station = MockData.stationIndex[stationCode]
        if (station?.statut?.name == "MAINTENANCE") {
            return ValidationResult(false, "Fenetre refusee : station en maintenance")
        }

        return ValidationResult(true)
    }
}
