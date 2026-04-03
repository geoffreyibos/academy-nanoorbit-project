package com.efrei.nanoorbit

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.efrei.nanoorbit.ui.navigation.NanoOrbitNavGraph
import com.efrei.nanoorbit.ui.theme.NanoOrbitTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            NanoOrbitTheme {
                NanoOrbitNavGraph()
            }
        }
    }
}
