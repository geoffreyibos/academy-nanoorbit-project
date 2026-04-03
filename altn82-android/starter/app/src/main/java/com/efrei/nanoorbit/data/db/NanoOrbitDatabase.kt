package com.efrei.nanoorbit.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [SatelliteEntity::class, FenetreEntity::class],
    version = 1,
    exportSchema = false
)
abstract class NanoOrbitDatabase : RoomDatabase() {
    abstract fun satelliteDao(): SatelliteDao
    abstract fun fenetreDao(): FenetreDao

    companion object {
        @Volatile
        private var instance: NanoOrbitDatabase? = null

        fun getInstance(context: Context): NanoOrbitDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    NanoOrbitDatabase::class.java,
                    "nanoorbit.db"
                ).build().also { instance = it }
            }
    }
}
