package com.efrei.nanoorbit.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = OrbitBlue,
    secondary = Aurora,
    background = Cloud,
    surface = Card,
    onPrimary = Card,
    onSecondary = Card,
    onBackground = SpaceBlue,
    onSurface = SpaceBlue
)

private val DarkColors = darkColorScheme(
    primary = Aurora,
    secondary = OrbitBlue
)

@Composable
fun NanoOrbitTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors,
        typography = Typography,
        content = content
    )
}
