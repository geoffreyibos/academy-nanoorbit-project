package com.efrei.nanoorbit.data.repository

import com.efrei.nanoorbit.data.api.NanoOrbitApi
import com.efrei.nanoorbit.data.api.NanoOrbitApiFactory
import com.efrei.nanoorbit.data.db.FenetreDao
import com.efrei.nanoorbit.data.db.SatelliteDao
import com.efrei.nanoorbit.data.db.StationDao
import com.efrei.nanoorbit.data.db.toDomain
import com.efrei.nanoorbit.data.db.toEntity
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.MockData
import com.efrei.nanoorbit.data.models.RepositoryPayload
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.SatelliteDetail
import com.efrei.nanoorbit.data.models.StationSol
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.data.models.StatutStation
import com.efrei.nanoorbit.data.models.ValidationResult
import java.time.Duration
import java.time.LocalDateTime

class NanoOrbitRepository(
    private val satelliteDao: SatelliteDao,
    private val fenetreDao: FenetreDao,
    private val stationDao: StationDao,
    private val api: NanoOrbitApi = NanoOrbitApiFactory.create()
) {
    suspend fun getFenetresLocalOrMock(): RepositoryPayload<List<FenetreCom>> {
        val cached = fenetreDao.getAll()
        if (cached.isNotEmpty()) {
            val latestUpdate = cached.maxOf { it.updatedAtMillis }
            return RepositoryPayload(
                data = cached.map { it.toDomain() },
                isOffline = true,
                cacheAgeMinutes = Duration.between(
                    java.time.Instant.ofEpochMilli(latestUpdate),
                    java.time.Instant.now()
                ).toMinutes(),
                usesMockData = false
            )
        }

        return RepositoryPayload(
            data = MockData.fenetres,
            isOffline = true,
            cacheAgeMinutes = null,
            usesMockData = true
        )
    }

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
                ).toMinutes(),
                usesMockData = false
            )
        }
        return refreshSatellites()
    }

    suspend fun refreshSatellites(): RepositoryPayload<List<Satellite>> {
        return runCatching {
            val remote = api.getSatellites().map { it.toDomain() }
            val updatedAt = System.currentTimeMillis()
            satelliteDao.upsertAll(remote.map { it.toEntity(updatedAt) })
            RepositoryPayload(
                data = remote,
                isOffline = false,
                cacheAgeMinutes = 0L,
                usesMockData = false
            )
        }.getOrElse {
            val cached = satelliteDao.getAll()
            if (cached.isNotEmpty()) {
                val latestUpdate = cached.maxOf { it.updatedAtMillis }
                RepositoryPayload(
                    data = cached.map { it.toDomain() },
                    isOffline = true,
                    cacheAgeMinutes = ageInMinutes(latestUpdate),
                    usesMockData = false
                )
            } else {
                RepositoryPayload(
                    data = MockData.satellites,
                    isOffline = true,
                    cacheAgeMinutes = null,
                    usesMockData = true
                )
            }
        }
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
                ).toMinutes(),
                usesMockData = false
            )
        }
        return refreshFenetres()
    }

    suspend fun refreshFenetres(): RepositoryPayload<List<FenetreCom>> {
        return runCatching {
            val remote = api.getFenetres().map { it.toDomain() }
            val upcoming = remote.filterRelevantFenetres()
            val updatedAt = System.currentTimeMillis()
            fenetreDao.upsertAll(upcoming.map { it.toEntity(updatedAt) })
            RepositoryPayload(
                data = upcoming,
                isOffline = false,
                cacheAgeMinutes = 0L,
                usesMockData = false
            )
        }.getOrElse {
            val cached = fenetreDao.getAll()
            if (cached.isNotEmpty()) {
                val latestUpdate = cached.maxOf { it.updatedAtMillis }
                RepositoryPayload(
                    data = cached.map { it.toDomain() },
                    isOffline = true,
                    cacheAgeMinutes = ageInMinutes(latestUpdate),
                    usesMockData = false
                )
            } else {
                RepositoryPayload(
                    data = MockData.fenetres.filterRelevantFenetres(),
                    isOffline = true,
                    cacheAgeMinutes = null,
                    usesMockData = true
                )
            }
        }
    }

    suspend fun getStationsCacheFirst(): RepositoryPayload<List<StationSol>> {
        val cached = stationDao.getAll()
        if (cached.isNotEmpty()) {
            val latestUpdate = cached.maxOf { it.updatedAtMillis }
            return RepositoryPayload(
                data = cached.map { it.toDomain() },
                isOffline = true,
                cacheAgeMinutes = ageInMinutes(latestUpdate),
                usesMockData = false
            )
        }
        return refreshStations()
    }

    suspend fun refreshStations(): RepositoryPayload<List<StationSol>> =
        runCatching {
            val remote = api.getStations().map { it.toDomain() }
            val updatedAt = System.currentTimeMillis()
            stationDao.upsertAll(remote.map { it.toEntity(updatedAt) })
            RepositoryPayload(
                data = remote,
                isOffline = false,
                cacheAgeMinutes = 0L,
                usesMockData = false
            )
        }.getOrElse {
            val cached = stationDao.getAll()
            if (cached.isNotEmpty()) {
                val latestUpdate = cached.maxOf { it.updatedAtMillis }
                RepositoryPayload(
                    data = cached.map { it.toDomain() },
                    isOffline = true,
                    cacheAgeMinutes = ageInMinutes(latestUpdate),
                    usesMockData = false
                )
            } else {
                RepositoryPayload(
                    data = MockData.stations,
                    isOffline = true,
                    cacheAgeMinutes = null,
                    usesMockData = true
                )
            }
        }

    suspend fun getSatelliteDetail(satelliteId: String): SatelliteDetail? =
        runCatching { api.getSatelliteDetail(satelliteId)?.toDomain() }
            .getOrElse { MockData.detailForSatellite(satelliteId) }
            ?: MockData.detailForSatellite(satelliteId)

    fun formatLastSyncAge(cacheAgeMinutes: Long?): String? =
        cacheAgeMinutes?.let { "Derniere synchronisation reussie il y a $it min" }

    fun validateFenetreCreation(
        satellite: Satellite?,
        station: StationSol?,
        dureeSecondes: Int
    ): ValidationResult {
        if (dureeSecondes !in 1..900) {
            return ValidationResult(false, "Duree invalide : entre 1 et 900 secondes")
        }

        if (satellite == null) {
            return ValidationResult(false, "Satellite inconnu")
        }
        if (satellite.statut == StatutSatellite.DESORBITE) {
            return ValidationResult(false, "Fenetre refusee : satellite desorbite")
        }
        if (station == null) {
            return ValidationResult(false, "Station inconnue")
        }
        if (station.statut == StatutStation.MAINTENANCE) {
            return ValidationResult(false, "Fenetre refusee : station en maintenance")
        }

        return ValidationResult(true)
    }

    suspend fun saveLocalFenetre(fenetre: FenetreCom) {
        fenetreDao.upsertAll(listOf(fenetre.toEntity(System.currentTimeMillis())))
    }

    private fun ageInMinutes(updatedAtMillis: Long): Long =
        Duration.between(
            java.time.Instant.ofEpochMilli(updatedAtMillis),
            java.time.Instant.now()
        ).toMinutes()

    private fun List<FenetreCom>.filterRelevantFenetres(): List<FenetreCom> = filter {
        Duration.between(LocalDateTime.now(), it.datetimeDebut).toDays() <= 7 ||
            it.datetimeDebut.isBefore(LocalDateTime.now())
    }
}
