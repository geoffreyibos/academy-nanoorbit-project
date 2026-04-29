package com.efrei.nanoorbit.ui.planning

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
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
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.ui.components.FenetreCard
import com.efrei.nanoorbit.ui.notifications.NanoOrbitNotificationWorker
import com.efrei.nanoorbit.viewmodel.NanoOrbitViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PlanningScreen(viewModel: NanoOrbitViewModel) {
    val context = LocalContext.current
    val satellites by viewModel.satellites.collectAsStateWithLifecycle()
    val stations by viewModel.stations.collectAsStateWithLifecycle()
    val fenetres by viewModel.filteredFenetres.collectAsStateWithLifecycle()
    val selectedStation by viewModel.selectedStationCode.collectAsStateWithLifecycle()
    val validationMessage by viewModel.planningValidationMessage.collectAsStateWithLifecycle()
    var satelliteId by remember { mutableStateOf("SAT-001") }
    var stationCode by remember { mutableStateOf("GS-TLS-01") }
    var duree by remember { mutableStateOf("420") }
    var satelliteMenuExpanded by remember { mutableStateOf(false) }
    var stationMenuExpanded by remember { mutableStateOf(false) }
    val notificationPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) {
            NanoOrbitNotificationWorker.showTestNotification(context, satelliteId, stationCode, duree.toIntOrNull() ?: 0)
        } else {
            Toast.makeText(context, "Permission notification refusee", Toast.LENGTH_SHORT).show()
        }
    }

    val totalDuree = fenetres.sumOf { it.dureeSecondes }
    val totalVolume = fenetres.sumOf { it.volumeDonnees ?: 0.0 }

    LaunchedEffect(satellites, stations) {
        if (satellites.isNotEmpty() && satellites.none { it.idSatellite == satelliteId }) {
            satelliteId = satellites.first().idSatellite
        }
        if (stations.isNotEmpty() && stations.none { it.codeStation == stationCode }) {
            stationCode = stations.first().codeStation
        }
    }

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
            ExposedDropdownMenuBox(
                expanded = satelliteMenuExpanded,
                onExpandedChange = { satelliteMenuExpanded = it }
            ) {
                OutlinedTextField(
                    value = satellites.firstOrNull { it.idSatellite == satelliteId }?.let {
                        "${it.idSatellite} - ${it.nomSatellite}"
                    } ?: satelliteId,
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .menuAnchor()
                        .fillMaxWidth(),
                    label = { Text("Satellite") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(satelliteMenuExpanded) }
                )
                ExposedDropdownMenu(
                    expanded = satelliteMenuExpanded,
                    onDismissRequest = { satelliteMenuExpanded = false }
                ) {
                    satellites.forEach { satellite ->
                        DropdownMenuItem(
                            text = { Text("${satellite.idSatellite} - ${satellite.nomSatellite}") },
                            onClick = {
                                satelliteId = satellite.idSatellite
                                satelliteMenuExpanded = false
                            }
                        )
                    }
                }
            }
            ExposedDropdownMenuBox(
                expanded = stationMenuExpanded,
                onExpandedChange = { stationMenuExpanded = it }
            ) {
                OutlinedTextField(
                    value = stations.firstOrNull { it.codeStation == stationCode }?.let {
                        "${it.codeStation} - ${it.nomStation}"
                    } ?: stationCode,
                    onValueChange = {},
                    readOnly = true,
                    modifier = Modifier
                        .menuAnchor()
                        .fillMaxWidth(),
                    label = { Text("Station") },
                    trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(stationMenuExpanded) }
                )
                ExposedDropdownMenu(
                    expanded = stationMenuExpanded,
                    onDismissRequest = { stationMenuExpanded = false }
                ) {
                    stations.forEach { station ->
                        DropdownMenuItem(
                            text = { Text("${station.codeStation} - ${station.nomStation}") },
                            onClick = {
                                stationCode = station.codeStation
                                stationMenuExpanded = false
                            }
                        )
                    }
                }
            }
            OutlinedTextField(value = duree, onValueChange = { duree = it }, modifier = Modifier.fillMaxWidth(), label = { Text("Duree (1..900)") })
            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = { viewModel.createPlanningFenetre(satelliteId, stationCode, duree.toIntOrNull() ?: 0) }
            ) {
                Text("Creer la fenetre")
            }
            Button(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    val needsPermission = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
                        PackageManager.PERMISSION_GRANTED
                    if (needsPermission) {
                        notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
                    } else {
                        NanoOrbitNotificationWorker.showTestNotification(context, satelliteId, stationCode, duree.toIntOrNull() ?: 0)
                    }
                }
            ) {
                Text("Tester notification")
            }
            validationMessage?.let {
                Text(
                    text = it,
                    color = if (it.startsWith("Validation OK") || it.startsWith("Fenetre creee")) {
                        MaterialTheme.colorScheme.primary
                    } else {
                        MaterialTheme.colorScheme.error
                    }
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
