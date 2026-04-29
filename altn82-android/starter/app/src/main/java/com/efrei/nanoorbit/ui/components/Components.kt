package com.efrei.nanoorbit.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.Instrument
import com.efrei.nanoorbit.data.models.MockData
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StatutFenetre
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.ui.theme.Danger
import com.efrei.nanoorbit.ui.theme.Neutral
import com.efrei.nanoorbit.ui.theme.OrbitBlue
import com.efrei.nanoorbit.ui.theme.Success
import com.efrei.nanoorbit.ui.theme.Warning
import java.time.format.DateTimeFormatter

@Composable
fun StatusBadge(statut: StatutSatellite, modifier: Modifier = Modifier) {
    AssistChip(
        modifier = modifier,
        onClick = {},
        enabled = false,
        colors = AssistChipDefaults.assistChipColors(
            disabledContainerColor = statusColor(statut).copy(alpha = 0.14f),
            disabledLabelColor = statusColor(statut)
        ),
        label = { Text(statutLabel(statut)) }
    )
}

@Composable
fun SatelliteCard(
    satellite: Satellite,
    orbiteLabel: String,
    onClick: () -> Unit
) {
    val isDisabled = satellite.statut == StatutSatellite.DESORBITE
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .alpha(if (isDisabled) 0.55f else 1f)
            .clickable(enabled = !isDisabled, onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(text = satellite.nomSatellite, style = MaterialTheme.typography.titleMedium)
                Text(text = "${satellite.formatCubesat.label} - $orbiteLabel", style = MaterialTheme.typography.bodyMedium)
                if (isDisabled) {
                    Text("DESORBITE", color = Neutral, style = MaterialTheme.typography.labelLarge)
                }
            }
            StatusBadge(statut = satellite.statut)
        }
    }
}

@Composable
fun FenetreCard(fenetre: FenetreCom, nomStation: String) {
    val color = when (fenetre.statut) {
        StatutFenetre.PLANIFIEE -> OrbitBlue
        StatutFenetre.REALISEE -> Success
        StatutFenetre.ANNULEE -> Danger
    }
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = color.copy(alpha = 0.08f))
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = nomStation, style = MaterialTheme.typography.titleMedium)
            Text(text = fenetre.datetimeDebut.format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")))
            Text(text = "Duree : ${fenetre.dureeSecondes}s")
            Text(
                text = "Statut : ${fenetre.statut.name}",
                modifier = Modifier
                    .background(color.copy(alpha = 0.16f), RoundedCornerShape(100))
                    .padding(horizontal = 10.dp, vertical = 4.dp),
                color = color
            )
            if (fenetre.volumeDonnees != null) {
                Text(text = "Volume : ${fenetre.volumeDonnees} Mo")
            }
        }
    }
}

@Composable
fun InstrumentItem(instrument: Instrument, etatFonctionnement: String) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(text = instrument.typeInstrument, style = MaterialTheme.typography.titleSmall)
            Text(text = instrument.modele)
            Text(text = "Resolution : ${instrument.resolution?.toString() ?: "N/A"}")
            Text(text = "Etat : $etatFonctionnement")
        }
    }
}

fun statusColor(statut: StatutSatellite): Color = when (statut) {
    StatutSatellite.OPERATIONNEL -> Success
    StatutSatellite.EN_VEILLE -> Warning
    StatutSatellite.DEFAILLANT -> Danger
    StatutSatellite.DESORBITE -> Neutral
}

fun statutLabel(statut: StatutSatellite): String = when (statut) {
    StatutSatellite.OPERATIONNEL -> "Operationnel"
    StatutSatellite.EN_VEILLE -> "En veille"
    StatutSatellite.DEFAILLANT -> "Defaillant"
    StatutSatellite.DESORBITE -> "Desorbite"
}

@Preview(showBackground = true)
@Composable
private fun SatelliteCardPreview() = SatelliteCard(MockData.satellites.first(), "SSO", onClick = {})

@Preview(showBackground = true)
@Composable
private fun StatusBadgePreview() = StatusBadge(StatutSatellite.EN_VEILLE)

@Preview(showBackground = true)
@Composable
private fun FenetreCardPreview() = FenetreCard(MockData.fenetres.first(), "Kiruna Arctic Station")

@Preview(showBackground = true)
@Composable
private fun InstrumentItemPreview() = InstrumentItem(MockData.instruments.first(), "Nominal")
