package com.efrei.nanoorbit.ui.navigation

sealed class Routes(val route: String) {
    data object Dashboard : Routes("dashboard")
    data object Planning : Routes("planning")
    data object Map : Routes("map")
    data object Detail : Routes("detail/{satelliteId}") {
        fun create(satelliteId: String): String = "detail/$satelliteId"
    }
}
