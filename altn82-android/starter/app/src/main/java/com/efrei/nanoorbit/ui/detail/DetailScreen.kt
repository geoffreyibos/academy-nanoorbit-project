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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
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
    val detail by viewModel.selectedDetail.collectAsStateWithLifecycle()
    val isLoading by viewModel.isDetailLoading.collectAsStateWithLifecycle()
    var anomalyText by remember { mutableStateOf("") }
    var anomalyError by remember { mutableStateOf(false) }
    var anomalyConfirmation by remember { mutableStateOf<String?>(null) }
    var showDialog by remember { mutableStateOf(false) }

    LaunchedEffect(satelliteId) {
        viewModel.loadDetail(satelliteId)
    }

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
        if (isLoading && detail == null) {
            Column(modifier = Modifier.padding(innerPadding).padding(16.dp)) {
                Text("Chargement du detail...")
            }
            return@Scaffold
        }

        val currentDetail = detail

        if (currentDetail == null) {
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
                    StatusBadge(currentDetail.satellite.statut)
                    Text("Format : ${currentDetail.satellite.formatCubesat.label}")
                    Text("Orbite : ${currentDetail.orbite?.typeOrbite?.name.orEmpty()} - ${currentDetail.orbite?.altitude ?: "-"} km")
                }
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Telemetrie", style = MaterialTheme.typography.titleMedium)
                    Text("Masse : ${currentDetail.satellite.masse ?: "-"} kg")
                    Text("Capacite batterie : ${currentDetail.satellite.capaciteBatterie ?: "-"} Wh")
                    Text("Vie restante estimee : ${currentDetail.satellite.dureeVieRestanteMois() ?: "-"} mois")
                }
            }
            item { Text("Instruments embarques", style = MaterialTheme.typography.titleMedium) }
            items(currentDetail.instruments, key = { it.instrument.refInstrument }) {
                InstrumentItem(it.instrument, it.etatFonctionnement)
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("Missions", style = MaterialTheme.typography.titleMedium)
                    currentDetail.missions
                        .filter { it.mission.statutMission == StatutMission.ACTIVE }
                        .forEach { mission ->
                        Text("${mission.mission.nomMission} - ${mission.roleSatellite}")
                    }
                }
            }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(onClick = {
                        anomalyError = false
                        showDialog = true
                    }) {
                        Text("Signaler une anomalie")
                    }
                    anomalyConfirmation?.let {
                        Text(it, color = MaterialTheme.colorScheme.primary)
                    }
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
                    onValueChange = {
                        anomalyText = it
                        anomalyError = false
                    },
                    label = { Text("Description libre") },
                    isError = anomalyError,
                    supportingText = {
                        if (anomalyError) {
                            Text("La description est obligatoire")
                        }
                    }
                )
            },
            confirmButton = {
                Button(onClick = {
                    if (anomalyText.isBlank()) {
                        anomalyError = true
                    } else {
                        viewModel.reportAnomaly(satelliteId)
                        anomalyConfirmation = "Anomalie signalee : satellite passe en statut Defaillant"
                        anomalyText = ""
                        anomalyError = false
                        showDialog = false
                    }
                }) {
                    Text("Envoyer")
                }
            },
            dismissButton = {
                Button(onClick = {
                    anomalyError = false
                    showDialog = false
                }) {
                    Text("Annuler")
                }
            }
        )
    }
}
