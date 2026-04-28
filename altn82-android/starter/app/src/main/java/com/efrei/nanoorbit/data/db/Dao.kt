package com.efrei.nanoorbit.data.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface SatelliteDao {
    @Query("SELECT * FROM satellites ORDER BY nomSatellite")
    suspend fun getAll(): List<SatelliteEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(items: List<SatelliteEntity>)

    @Query("UPDATE satellites SET statut = :statut, updatedAtMillis = :updatedAtMillis WHERE idSatellite = :idSatellite")
    suspend fun updateStatus(idSatellite: String, statut: String, updatedAtMillis: Long)
}

@Dao
interface FenetreDao {
    @Query("SELECT * FROM fenetres_com ORDER BY datetimeDebut")
    suspend fun getAll(): List<FenetreEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(items: List<FenetreEntity>)
}

@Dao
interface StationDao {
    @Query("SELECT * FROM stations_sol ORDER BY nomStation")
    suspend fun getAll(): List<StationEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertAll(items: List<StationEntity>)
}

@Dao
interface SatelliteStatusOverrideDao {
    @Query("SELECT * FROM satellite_status_overrides")
    suspend fun getAll(): List<SatelliteStatusOverrideEntity>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(item: SatelliteStatusOverrideEntity)
}
