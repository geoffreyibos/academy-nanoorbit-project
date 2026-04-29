package com.efrei.nanoorbit.data.api

import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.FormatCubeSat
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.Mission
import com.efrei.nanoorbit.data.models.MissionParticipation
import com.efrei.nanoorbit.data.models.Orbite
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.SatelliteDetail
import com.efrei.nanoorbit.data.models.SatelliteInstrument
import com.efrei.nanoorbit.data.models.StatutFenetre
import com.efrei.nanoorbit.data.models.StatutMission
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.data.models.StatutStation
import com.efrei.nanoorbit.data.models.StationSol
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
    @SerializedName(value = "orbiteType", alternate = ["type_orbite"])
    val orbiteType: String? = null,
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
        orbiteType = orbiteType,
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

data class RemoteStationDto(
    @SerializedName(value = "codeStation", alternate = ["code_station"])
    val codeStation: String,
    @SerializedName(value = "nomStation", alternate = ["nom_station"])
    val nomStation: String,
    @SerializedName("latitude")
    val latitude: Double,
    @SerializedName("longitude")
    val longitude: Double,
    @SerializedName(value = "diametreAntenne", alternate = ["diametre_antenne_m"])
    val diametreAntenne: Double? = null,
    @SerializedName(value = "bandeFrequence", alternate = ["bande_frequence"])
    val bandeFrequence: String? = null,
    @SerializedName(value = "debitMax", alternate = ["debit_max_mbps"])
    val debitMax: Double? = null,
    @SerializedName("statut")
    val statut: String
) {
    fun toDomain(): StationSol = StationSol(
        codeStation = codeStation,
        nomStation = nomStation,
        latitude = latitude,
        longitude = longitude,
        diametreAntenne = diametreAntenne,
        bandeFrequence = bandeFrequence,
        debitMax = debitMax,
        statut = enumValueOf(statut)
    )
}

data class RemoteOrbiteDto(
    @SerializedName(value = "idOrbite", alternate = ["id_orbite"])
    val idOrbite: Int,
    @SerializedName(value = "typeOrbite", alternate = ["type_orbite"])
    val typeOrbite: String,
    @SerializedName("altitude")
    val altitude: Double,
    @SerializedName("inclinaison")
    val inclinaison: Double,
    @SerializedName(value = "periodeOrbitale", alternate = ["periode_orbitale"])
    val periodeOrbitale: Double,
    @SerializedName("excentricite")
    val excentricite: Double,
    @SerializedName(value = "zoneCouverture", alternate = ["zone_couverture"])
    val zoneCouverture: String? = null
) {
    fun toDomain(): Orbite = Orbite(
        idOrbite = idOrbite,
        typeOrbite = enumValueOf(typeOrbite),
        altitude = altitude,
        inclinaison = inclinaison,
        periodeOrbitale = periodeOrbitale,
        excentricite = excentricite,
        zoneCouverture = zoneCouverture
    )
}

data class RemoteSatelliteInstrumentDto(
    @SerializedName("instrument")
    val instrument: RemoteInstrumentDto,
    @SerializedName("etatFonctionnement")
    val etatFonctionnement: String
) {
    fun toDomain(): SatelliteInstrument = SatelliteInstrument(
        instrument = instrument.toDomain(),
        etatFonctionnement = etatFonctionnement
    )
}

data class RemoteMissionDto(
    @SerializedName(value = "idMission", alternate = ["id_mission"])
    val idMission: String,
    @SerializedName(value = "nomMission", alternate = ["nom_mission"])
    val nomMission: String,
    @SerializedName("objectif")
    val objectif: String,
    @SerializedName(value = "dateDebut", alternate = ["date_debut"])
    val dateDebut: LocalDate,
    @SerializedName("statutMission")
    val statutMission: String,
    @SerializedName(value = "dateFin", alternate = ["date_fin"])
    val dateFin: LocalDate? = null,
    @SerializedName(value = "zoneGeoCible", alternate = ["zone_cible"])
    val zoneGeoCible: String? = null
) {
    fun toDomain(): Mission = Mission(
        idMission = idMission,
        nomMission = nomMission,
        objectif = objectif,
        dateDebut = dateDebut,
        statutMission = enumValueOf(statutMission),
        dateFin = dateFin,
        zoneGeoCible = zoneGeoCible
    )
}

data class RemoteMissionParticipationDto(
    @SerializedName("mission")
    val mission: RemoteMissionDto,
    @SerializedName("roleSatellite")
    val roleSatellite: String
) {
    fun toDomain(): MissionParticipation = MissionParticipation(
        mission = mission.toDomain(),
        roleSatellite = roleSatellite
    )
}

data class RemoteSatelliteDetailDto(
    @SerializedName("satellite")
    val satellite: RemoteSatelliteDto,
    @SerializedName("orbite")
    val orbite: RemoteOrbiteDto?,
    @SerializedName("instruments")
    val instruments: List<RemoteSatelliteInstrumentDto>,
    @SerializedName("missions")
    val missions: List<RemoteMissionParticipationDto>
) {
    fun toDomain(): SatelliteDetail = SatelliteDetail(
        satellite = satellite.toDomain(),
        orbite = orbite?.toDomain(),
        instruments = instruments.map { it.toDomain() },
        missions = missions.map { it.toDomain() }
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
