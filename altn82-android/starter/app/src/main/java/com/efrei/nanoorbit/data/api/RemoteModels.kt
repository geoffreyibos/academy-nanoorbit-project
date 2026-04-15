package com.efrei.nanoorbit.data.api

import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.FormatCubeSat
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StatutFenetre
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.google.gson.annotations.SerializedName
import java.time.LocalDate
import java.time.LocalDateTime

data class RemoteSatelliteDto(
    @SerializedName(value = "idSatellite", alternate = ["id_satellite"])
    val idSatellite: String,
    @SerializedName(value = "nomSatellite", alternate = ["nom_satellite"])
    val nomSatellite: String,
    @SerializedName("statut")
    val statut: String,
    @SerializedName(value = "formatCubesat", alternate = ["format_cubesat"])
    val formatCubesat: String,
    @SerializedName(value = "idOrbite", alternate = ["id_orbite"])
    val idOrbite: Int,
    @SerializedName(value = "dateLancement", alternate = ["date_lancement"])
    val dateLancement: LocalDate? = null,
    @SerializedName("masse")
    val masse: Double? = null,
    @SerializedName(value = "dureeViePrevueMois", alternate = ["duree_vie_prevue", "dureeViePrevue"])
    val dureeViePrevueMois: Int? = null,
    @SerializedName(value = "capaciteBatterie", alternate = ["capacite_batterie"])
    val capaciteBatterie: Int? = null
) {
    fun toDomain(): Satellite = Satellite(
        idSatellite = idSatellite,
        nomSatellite = nomSatellite,
        statut = enumValueOf(statut),
        formatCubesat = formatCubeSatOf(formatCubesat),
        idOrbite = idOrbite,
        dateLancement = dateLancement,
        masse = masse,
        dureeViePrevueMois = dureeViePrevueMois,
        capaciteBatterie = capaciteBatterie
    )
}

data class RemoteInstrumentDto(
    @SerializedName(value = "refInstrument", alternate = ["ref_instrument"])
    val refInstrument: String,
    @SerializedName(value = "typeInstrument", alternate = ["type_instrument"])
    val typeInstrument: String,
    @SerializedName("modele")
    val modele: String,
    @SerializedName("resolution")
    val resolution: Double? = null,
    @SerializedName("consommation")
    val consommation: Double? = null,
    @SerializedName("masse")
    val masse: Double? = null
) {
    fun toDomain(): Instrument = Instrument(
        refInstrument = refInstrument,
        typeInstrument = typeInstrument,
        modele = modele,
        resolution = resolution,
        consommation = consommation,
        masse = masse
    )
}

data class RemoteFenetreDto(
    @SerializedName(value = "idFenetre", alternate = ["id_fenetre"])
    val idFenetre: Int,
    @SerializedName(value = "datetimeDebut", alternate = ["datetime_debut"])
    val datetimeDebut: LocalDateTime,
    @SerializedName(value = "dureeSecondes", alternate = ["duree", "duree_secondes"])
    val dureeSecondes: Int,
    @SerializedName(value = "elevationMax", alternate = ["elevation_max"])
    val elevationMax: Double,
    @SerializedName("statut")
    val statut: String,
    @SerializedName(value = "idSatellite", alternate = ["id_satellite"])
    val idSatellite: String,
    @SerializedName(value = "codeStation", alternate = ["code_station"])
    val codeStation: String,
    @SerializedName(value = "volumeDonnees", alternate = ["volume_donnees"])
    val volumeDonnees: Double? = null
) {
    fun toDomain(): FenetreCom = FenetreCom(
        idFenetre = idFenetre,
        datetimeDebut = datetimeDebut,
        dureeSecondes = dureeSecondes,
        elevationMax = elevationMax,
        statut = enumValueOf(statut),
        idSatellite = idSatellite,
        codeStation = codeStation,
        volumeDonnees = volumeDonnees
    )
}

private fun formatCubeSatOf(raw: String): FormatCubeSat = when (raw.trim().uppercase()) {
    "1U", "U1" -> FormatCubeSat.U1
    "3U", "U3" -> FormatCubeSat.U3
    "6U", "U6" -> FormatCubeSat.U6
    "12U", "U12" -> FormatCubeSat.U12
    else -> error("Format CubeSat inconnu: $raw")
}

private inline fun <reified T : Enum<T>> enumValueOf(raw: String): T {
    val normalized = raw.trim().uppercase()
    return enumValues<T>().firstOrNull { it.name == normalized }
        ?: error("Valeur enum inconnue pour ${T::class.java.simpleName}: $raw")
}
