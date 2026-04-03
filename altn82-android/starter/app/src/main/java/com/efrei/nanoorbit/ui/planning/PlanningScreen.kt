package com.efrei.nanoorbit.ui.planning

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.ui.components.FenetreCard
import com.efrei.nanoorbit.viewmodel.NanoOrbitViewModel

@Composable
fun PlanningScreen(viewModel: NanoOrbitViewModel) {
    val stations by viewModel.stations.collectAsStateWithLifecycle()
    val fenetres by viewModel.filteredFenetres.collectAsStateWithLifecycle()
    val selectedStation by viewModel.selectedStationCode.collectAsStateWithLifecycle()
    val validationMessage by viewModel.planningValidationMessage.collectAsStateWithLifecycle()
    var satelliteId by remember { mutableStateOf("SAT-001") }
    var stationCode by remember { mutableStateOf("GS-TLS-01") }
    var duree by remember { mutableStateOf("420") }

    val totalDuree = fenetres.sumOf { it.dureeSecondes }
    val totalVolume = fenetres.sumOf { it.volumeDonnees ?: 0.0 }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("Planning des communications", style = MaterialTheme.typography.headlineSmall)
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            FilterChip(
                selected = selectedStation == null,
                onClick = { viewModel.onStationSelected(null) },
                label = { Text("Toutes") }
            )
            stations.forEach { station ->
                FilterChip(
                    selected = selectedStation == station.codeStation,
                    onClick = { viewModel.onStationSelected(station.codeStation) },
                    label = { Text(station.nomStation) }
                )
            }
        }
        Text("Duree totale : ${totalDuree}s")
        Text("Volume planifie : $totalVolume Mo")
        Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
            Text("Validation client RG-F04 / RG-S06", style = MaterialTheme.typography.titleMedium)
            OutlinedTextField(value = satelliteId, onValueChange = { satelliteId = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Satellite") })
            OutlinedTextField(value = stationCode, onValueChange = { stationCode = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Station") })
            OutlinedTextField(value = duree, onValueChange = { duree = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Duree (1..900)") })
            Button(onClick = { viewModel.validatePlanningInput(satelliteId, stationCode, duree.toIntOrNull() ?: 0) }) {
                Text("Valider une nouvelle fenetre")
            }
            validationMessage?.let {
                Text(
                    text = it,
                    color = if (it.startsWith("Validation OK")) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.error
                )
            }
        }
        LazyColumn(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            items(fenetres, key = { it.idFenetre }) { fenetre ->
                FenetreCard(fenetre, viewModel.getStationName(fenetre.codeStation))
            }
        }
    }
}
