package com.efrei.nanoorbit.ui.dashboard

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.ui.components.SatelliteCard
import com.efrei.nanoorbit.viewmodel.NanoOrbitViewModel

@Composable
fun DashboardScreen(
    viewModel: NanoOrbitViewModel,
    satellites: List<Satellite>,
    onSatelliteClick: (String) -> Unit
) {
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val errorMessage by viewModel.errorMessage.collectAsStateWithLifecycle()
    val query by viewModel.searchQuery.collectAsStateWithLifecycle()
    val selectedStatut by viewModel.selectedStatut.collectAsStateWithLifecycle()
    val isOffline by viewModel.isOfflineMode.collectAsStateWithLifecycle()
    val cacheAge by viewModel.cacheAgeLabel.collectAsStateWithLifecycle()

    // Q1: LazyColumn only composes the visible cards. A plain Column with 100 satellites would
    // inflate every row immediately, increasing memory cost and slowing scroll/recomposition.
    // Q2: enum class prevents invalid free-text statuses and keeps Android aligned with Oracle CHECK.
    // Q3: DESORBITE cards are greyed out and non-clickable so the user cannot initiate planning,
    // which mirrors the Oracle trigger that rejects forbidden communication windows server-side.
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("NanoOrbit Ground Control", style = MaterialTheme.typography.headlineSmall)
        if (isOffline) {
            Text("Mode hors-ligne${cacheAge?.let { " - $it" }.orEmpty()}", color = MaterialTheme.colorScheme.primary)
        }
        OutlinedTextField(
            value = query,
            onValueChange = viewModel::onSearchQueryChange,
            modifier = Modifier.fillMaxWidth(),
            label = { Text("Rechercher par nom ou type d'orbite") }
        )
        Row(
            modifier = Modifier.horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            FilterChip(
                selected = selectedStatut == null,
                onClick = { viewModel.onStatutFilterChange(null) },
                label = { Text("Tous") }
            )
            StatutSatellite.entries.forEach { statut ->
                FilterChip(
                    selected = selectedStatut == statut,
                    onClick = { viewModel.onStatutFilterChange(statut) },
                    label = { Text(statut.name) }
                )
            }
        }
        Text(viewModel.getOperationalCountLabel())
        Text(viewModel.getResultCountLabel(), style = MaterialTheme.typography.labelLarge)
        if (isLoading) {
            CircularProgressIndicator()
            Text("Chargement des satellites...")
        }
        if (errorMessage != null) {
            Text(errorMessage.orEmpty(), color = MaterialTheme.colorScheme.error)
            FilledTonalButton(onClick = viewModel::refreshSatellites) {
                Text("Reessayer")
            }
        }
        LazyColumn(
            contentPadding = PaddingValues(bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(satellites, key = { it.idSatellite }) { satellite ->
                SatelliteCard(
                    satellite = satellite,
                    orbiteLabel = viewModel.getDetail(satellite.idSatellite)?.orbite?.typeOrbite?.name.orEmpty(),
                    onClick = { onSatelliteClick(satellite.idSatellite) }
                )
            }
        }
    }
}
