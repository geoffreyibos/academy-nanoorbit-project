package com.efrei.nanoorbit.ui.map

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MyLocation
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.efrei.nanoorbit.data.models.StatutStation
import com.efrei.nanoorbit.viewmodel.NanoOrbitViewModel
import com.google.android.gms.location.LocationServices
import org.osmdroid.util.GeoPoint
import org.osmdroid.views.MapView
import org.osmdroid.views.overlay.Marker
import kotlin.math.roundToInt

@SuppressLint("MissingPermission")
@Composable
fun MapScreen(viewModel: NanoOrbitViewModel) {
    val context = LocalContext.current
    val stations by viewModel.stations.collectAsStateWithLifecycle()
    val fusedClient = LocationServices.getFusedLocationProviderClient(context)
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
    val mapView = remember { MapView(context) }
    var operatorLocation by remember { mutableStateOf<android.location.Location?>(null) }

    DisposableEffect(Unit) {
        mapView.setMultiTouchControls(true)
        mapView.controller.setZoom(2.8)
        mapView.controller.setCenter(GeoPoint(32.0, 15.0))
        onDispose { mapView.onDetach() }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = {
                mapView.apply {
                    overlays.clear()
                    stations.forEach { station ->
                        overlays.add(
                            Marker(this).apply {
                                position = GeoPoint(station.latitude, station.longitude)
                                title = station.nomStation
                                snippet = buildString {
                                    append("Bande ${station.bandeFrequence} - Debit ${station.debitMax} Mb/s\n")
                                    append(
                                        when (station.statut) {
                                            StatutStation.ACTIVE -> "Operationnelle"
                                            StatutStation.MAINTENANCE -> "En maintenance"
                                            StatutStation.HORS_SERVICE -> "Hors service"
                                        }
                                    )
                                    operatorLocation?.let { location ->
                                        val result = FloatArray(1)
                                        android.location.Location.distanceBetween(
                                            location.latitude,
                                            location.longitude,
                                            station.latitude,
                                            station.longitude,
                                            result
                                        )
                                        append("\nDistance : ${(result[0] / 1000f).roundToInt()} km")
                                    }
                                }
                                setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                            }
                        )
                    }
                    invalidate()
                }
            },
            update = { view ->
                view.overlays.removeAll { it is Marker }
                stations.forEach { station ->
                    view.overlays.add(
                        Marker(view).apply {
                            position = GeoPoint(station.latitude, station.longitude)
                            title = station.nomStation
                            snippet = buildString {
                                append("Bande ${station.bandeFrequence} - Debit ${station.debitMax} Mb/s")
                                operatorLocation?.let { location ->
                                    val result = FloatArray(1)
                                    android.location.Location.distanceBetween(
                                        location.latitude,
                                        location.longitude,
                                        station.latitude,
                                        station.longitude,
                                        result
                                    )
                                    append("\nDistance : ${(result[0] / 1000f).roundToInt()} km")
                                }
                            }
                            setAnchor(Marker.ANCHOR_CENTER, Marker.ANCHOR_BOTTOM)
                        }
                    )
                }
                view.invalidate()
            }
        )

        FloatingActionButton(
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp),
            onClick = {
                val granted = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) ==
                    PackageManager.PERMISSION_GRANTED
                if (!granted) {
                    permissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)
                } else {
                    fusedClient.lastLocation.addOnSuccessListener { location ->
                        if (location != null) {
                            val point = GeoPoint(location.latitude, location.longitude)
                            mapView.controller.setZoom(5.5)
                            mapView.controller.setCenter(point)
                            operatorLocation = location
                            val distanceLabel = stations.joinToString(separator = "\n") { station ->
                                val result = FloatArray(1)
                                android.location.Location.distanceBetween(
                                    location.latitude,
                                    location.longitude,
                                    station.latitude,
                                    station.longitude,
                                    result
                                )
                                "${station.nomStation}: ${(result[0] / 1000f).roundToInt()} km"
                            }
                            mapView.overlays.add(
                                Marker(mapView).apply {
                                    position = point
                                    title = "Operateur"
                                    snippet = distanceLabel
                                }
                            )
                            mapView.invalidate()
                        }
                    }
                }
            }
        ) {
            Icon(Icons.Default.MyLocation, contentDescription = "Me localiser")
        }

        Text(
            text = "Carte OSM des stations au sol",
            modifier = Modifier
                .align(Alignment.TopStart)
                .padding(16.dp),
            style = MaterialTheme.typography.titleMedium
        )
    }
}
