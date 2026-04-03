package com.efrei.nanoorbit.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.efrei.nanoorbit.data.db.NanoOrbitDatabase
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.MockData
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.SatelliteDetail
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.data.models.StationSol
import com.efrei.nanoorbit.data.repository.NanoOrbitRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class NanoOrbitViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = NanoOrbitRepository(
        satelliteDao = NanoOrbitDatabase.getInstance(application).satelliteDao(),
        fenetreDao = NanoOrbitDatabase.getInstance(application).fenetreDao()
    )

    private val _satellites = MutableStateFlow<List<Satellite>>(emptyList())
    val satellites: StateFlow<List<Satellite>> = _satellites.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    private val _selectedStatut = MutableStateFlow<StatutSatellite?>(null)
    val selectedStatut: StateFlow<StatutSatellite?> = _selectedStatut.asStateFlow()

    private val _fenetres = MutableStateFlow<List<FenetreCom>>(emptyList())
    val fenetres: StateFlow<List<FenetreCom>> = _fenetres.asStateFlow()

    private val _stations = MutableStateFlow<List<StationSol>>(repository.getStations())
    val stations: StateFlow<List<StationSol>> = _stations.asStateFlow()

    private val _selectedStationCode = MutableStateFlow<String?>(null)
    val selectedStationCode: StateFlow<String?> = _selectedStationCode.asStateFlow()

    private val _isOfflineMode = MutableStateFlow(false)
    val isOfflineMode: StateFlow<Boolean> = _isOfflineMode.asStateFlow()

    private val _cacheAgeLabel = MutableStateFlow<String?>(null)
    val cacheAgeLabel: StateFlow<String?> = _cacheAgeLabel.asStateFlow()

    private val _planningValidationMessage = MutableStateFlow<String?>(null)
    val planningValidationMessage: StateFlow<String?> = _planningValidationMessage.asStateFlow()

    val filteredSatellites: StateFlow<List<Satellite>> = combine(
        satellites,
        searchQuery,
        selectedStatut
    ) { satellitesList, query, statut ->
        satellitesList.filter { satellite ->
            val matchesSearch = query.isBlank() ||
                satellite.nomSatellite.contains(query, ignoreCase = true) ||
                repository.getOrbiteTypeForSatellite(satellite.idSatellite).contains(query, ignoreCase = true)
            val matchesStatut = statut == null || satellite.statut == statut
            matchesSearch && matchesStatut
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val filteredFenetres: StateFlow<List<FenetreCom>> = combine(
        fenetres,
        selectedStationCode
    ) { windows, stationCode ->
        windows
            .filter { stationCode == null || it.codeStation == stationCode }
            .sortedBy { it.datetimeDebut }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        loadSatellites()
        loadFenetres()
    }

    fun loadSatellites() {
        viewModelScope.launch {
            _isLoading.value = true
            _errorMessage.value = null
            runCatching {
                repository.getSatellitesCacheFirst()
            }.onSuccess { payload ->
                _satellites.value = payload.data
                _isOfflineMode.value = payload.isOffline
                _cacheAgeLabel.value = repository.formatCacheAge(payload.cacheAgeMinutes)
                if (payload.isOffline) {
                    refreshSatellites()
                }
            }.onFailure {
                _errorMessage.value = "Impossible de charger les satellites."
            }
            _isLoading.value = false
        }
    }

    fun loadFenetres() {
        viewModelScope.launch {
            runCatching { repository.getFenetresCacheFirst() }
                .onSuccess { payload -> _fenetres.value = payload.data }
                .onFailure { _errorMessage.value = "Impossible de charger les fenetres." }
        }
    }

    fun onSearchQueryChange(query: String) {
        _searchQuery.value = query
    }

    fun onStatutFilterChange(statut: StatutSatellite?) {
        _selectedStatut.value = statut
    }

    fun onStationSelected(code: String?) {
        _selectedStationCode.value = code
    }

    fun refreshSatellites() {
        viewModelScope.launch {
            _isLoading.value = true
            runCatching { repository.refreshSatellites() }
                .onSuccess { payload ->
                    _satellites.value = payload.data
                    _isOfflineMode.value = false
                    _cacheAgeLabel.value = null
                }
                .onFailure { _errorMessage.value = "Erreur reseau lors du rafraichissement." }
            _isLoading.value = false
        }
    }

    fun refreshFenetres() {
        viewModelScope.launch {
            runCatching { repository.refreshFenetres() }
                .onSuccess { payload -> _fenetres.value = payload.data }
                .onFailure { _errorMessage.value = "Erreur reseau lors du rafraichissement des fenetres." }
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }

    fun getDetail(satelliteId: String): SatelliteDetail? = repository.getSatelliteDetail(satelliteId)

    fun getStationName(codeStation: String): String =
        stations.value.firstOrNull { it.codeStation == codeStation }?.nomStation ?: codeStation

    fun validatePlanningInput(satelliteId: String, stationCode: String, dureeSecondes: Int) {
        // Same client-side rule as Oracle RG-F04/T1: fail before the payload is sent.
        _planningValidationMessage.value = repository
            .validateFenetreCreation(satelliteId, stationCode, dureeSecondes)
            .message ?: "Validation OK : fenetre planifiable"
    }

    fun clearPlanningMessage() {
        _planningValidationMessage.value = null
    }

    fun getOperationalCountLabel(): String {
        val operational = satellites.value.count { it.statut == StatutSatellite.OPERATIONNEL }
        return "$operational/${satellites.value.size} satellites operationnels"
    }

    fun getResultCountLabel(): String = "${filteredSatellites.value.size} resultat(s)"

    fun getAllSatelliteIds(): List<String> = MockData.satellites.map { it.idSatellite }
}
