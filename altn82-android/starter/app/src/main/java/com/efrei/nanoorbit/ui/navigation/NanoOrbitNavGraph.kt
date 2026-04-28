package com.efrei.nanoorbit.ui.navigation

import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.efrei.nanoorbit.ui.dashboard.DashboardScreen
import com.efrei.nanoorbit.ui.detail.DetailScreen
import com.efrei.nanoorbit.ui.map.MapScreen
import com.efrei.nanoorbit.ui.planning.PlanningScreen
import com.efrei.nanoorbit.viewmodel.NanoOrbitViewModel

@Composable
fun NanoOrbitNavGraph(viewModel: NanoOrbitViewModel = viewModel()) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val currentRoute = backStackEntry?.destination?.route

    Scaffold(
        bottomBar = {
            if (currentRoute != Routes.Detail.route && currentRoute?.startsWith("detail/") != true) {
                val items = listOf(
                    Triple(Routes.Dashboard.route, "Dashboard", Icons.Default.Home),
                    Triple(Routes.Planning.route, "Planning", Icons.Default.Schedule),
                    Triple(Routes.Map.route, "Carte", Icons.Default.Map)
                )
                NavigationBar {
                    items.forEach { (route, label, icon) ->
                        val selected = backStackEntry?.destination?.hierarchy?.any { it.route == route } == true
                        NavigationBarItem(
                            selected = selected,
                            onClick = {
                                navController.navigate(route) {
                                    popUpTo(navController.graph.findStartDestination().id) {
                                        saveState = true
                                    }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(icon, contentDescription = label) },
                            label = { Text(label) }
                        )
                    }
                }
            }
        }
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Routes.Dashboard.route,
            modifier = Modifier.padding(innerPadding)
        ) {
            composable(Routes.Dashboard.route) {
                val satellites by viewModel.filteredSatellites.collectAsStateWithLifecycle()
                DashboardScreen(
                    viewModel = viewModel,
                    satellites = satellites,
                    onSatelliteClick = { navController.navigate(Routes.Detail.create(it)) }
                )
            }
            composable(Routes.Planning.route) { PlanningScreen(viewModel = viewModel) }
            composable(Routes.Map.route) { MapScreen(viewModel = viewModel) }
            composable(Routes.Detail.route) { entry ->
                DetailScreen(
                    satelliteId = entry.arguments?.getString("satelliteId").orEmpty(),
                    viewModel = viewModel,
                    onBack = {
                        viewModel.clearDetail()
                        navController.popBackStack()
                    }
                )
            }
        }
    }
}
