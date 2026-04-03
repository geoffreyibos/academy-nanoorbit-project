package com.efrei.nanoorbit.ui.detail

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.efrei.nanoorbit.ui.components.InstrumentItem
import com.efrei.nanoorbit.ui.components.StatusBadge
import com.efrei.nanoorbit.data.models.StatutMission
import com.efrei.nanoorbit.viewmodel.NanoOrbitViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    satelliteId: String,
    viewModel: NanoOrbitViewModel,
    onBack: () -> Unit
) {
    val detail = viewModel.getDetail(satelliteId)
    var anomalyText by remember { mutableStateOf("") }
    var showDialog by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(detail?.satellite?.nomSatellite ?: satelliteId) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Retour")
                    }
                }
            )
        }
    ) { innerPadding ->
        if (detail == null) {
            Column(modifier = Modifier.padding(innerPadding).padding(16.dp)) {
                Text("Satellite introuvable")
            }
            return@Scaffold
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                    Text("Statut", style = MaterialTheme.typography.titleMedium)
                    StatusBadge(detail.satellite.statut)
                    Text("Format : ${detail.satellite.formatCubesat.label}")
                    Text("Orbite : ${detail.orbite?.typeOrbite?.name.orEmpty()} - ${detail.orbite?.altitude ?: "-"} km")
                }
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Telemetrie", style = MaterialTheme.typography.titleMedium)
                    Text("Masse : ${detail.satellite.masse ?: "-"} kg")
                    Text("Capacite batterie : ${detail.satellite.capaciteBatterie ?: "-"} Wh")
                    Text("Vie restante estimee : ${detail.satellite.dureeVieRestanteMois() ?: "-"} mois")
                }
            }
            item { Text("Instruments embarques", style = MaterialTheme.typography.titleMedium) }
            items(detail.instruments, key = { it.instrument.refInstrument }) {
                InstrumentItem(it.instrument, it.etatFonctionnement)
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Missions", style = MaterialTheme.typography.titleMedium)
                    detail.missions
                        .filter { it.mission.statutMission == StatutMission.ACTIVE }
                        .forEach { mission ->
                        Text("${mission.mission.nomMission} - ${mission.roleSatellite}")
                    }
                }
            }
            item {
                Button(onClick = { showDialog = true }) {
                    Text("Signaler une anomalie")
                }
            }
        }
    }

    if (showDialog) {
        AlertDialog(
            onDismissRequest = { showDialog = false },
            title = { Text("Signaler une anomalie") },
            text = {
                OutlinedTextField(
                    value = anomalyText,
                    onValueChange = { anomalyText = it },
                    label = { Text("Description libre") }
                )
            },
            confirmButton = {
                Button(onClick = { showDialog = false }) {
                    Text("Envoyer")
                }
            },
            dismissButton = {
                Button(onClick = { showDialog = false }) {
                    Text("Annuler")
                }
            }
        )
    }
}
