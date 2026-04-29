package com.efrei.nanoorbit.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.efrei.nanoorbit.data.db.NanoOrbitDatabase
import com.efrei.nanoorbit.data.models.FenetreCom
import com.efrei.nanoorbit.data.models.RepositoryPayload
import com.efrei.nanoorbit.data.models.Satellite
import com.efrei.nanoorbit.data.models.SatelliteDetail
import com.efrei.nanoorbit.data.models.StatutFenetre
import com.efrei.nanoorbit.data.models.StatutSatellite
import com.efrei.nanoorbit.data.models.StationSol
import com.efrei.nanoorbit.data.repository.NanoOrbitRepository
import java.time.LocalDateTime
import kotlinx.coroutines.delay
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
        fenetreDao = NanoOrbitDatabase.getInstance(application).fenetreDao(),
        stationDao = NanoOrbitDatabase.getInstance(application).stationDao()
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

    private val _stations = MutableStateFlow<List<StationSol>>(emptyList())
    val stations: StateFlow<List<StationSol>> = _stations.asStateFlow()

    private val _selectedDetail = MutableStateFlow<SatelliteDetail?>(null)
    val selectedDetail: StateFlow<SatelliteDetail?> = _selectedDetail.asStateFlow()

    private val _isDetailLoading = MutableStateFlow(false)
    val isDetailLoading: StateFlow<Boolean> = _isDetailLoading.asStateFlow()

    private val _selectedStationCode = MutableStateFlow<String?>(null)
    val selectedStationCode: StateFlow<String?> = _selectedStationCode.asStateFlow()

    private val _isOfflineMode = MutableStateFlow(false)
    val isOfflineMode: StateFlow<Boolean> = _isOfflineMode.asStateFlow()

    private val _cacheAgeLabel = MutableStateFlow<String?>(null)
    val cacheAgeLabel: StateFlow<String?> = _cacheAgeLabel.asStateFlow()

    private val _planningValidationMessage = MutableStateFlow<String?>(null)
    val planningValidationMessage: StateFlow<String?> = _planningValidationMessage.asStateFlow()

    private val _mockDataWarning = MutableStateFlow<String?>(null)
    val mockDataWarning: StateFlow<String?> = _mockDataWarning.asStateFlow()

    private var lastSyncAgeMinutes: Long? = null

    val filteredSatellites: StateFlow<List<Satellite>> = combine(
        satellites,
        searchQuery,
        selectedStatut
    ) { satellitesList, query, statut ->
        satellitesList.filter { satellite ->
            val matchesSearch = query.isBlank() ||
                satellite.nomSatellite.contains(query, ignoreCase = true) ||
                satellite.orbiteType.orEmpty().contains(query, ignoreCase = true)
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
        loadStations()
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
                updateOfflineState(payload)
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
                .onSuccess { payload ->
                    _fenetres.value = payload.data
                    updateOfflineState(payload)
                    if (payload.isOffline) {
                        refreshFenetres()
                    }
                }
                .onFailure { _errorMessage.value = "Impossible de charger les fenetres." }
        }
    }

    fun loadStations() {
        viewModelScope.launch {
            runCatching { repository.getStationsCacheFirst() }
                .onSuccess { payload ->
                    _stations.value = payload.data
                    updateOfflineState(payload)
                    if (payload.usesMockData) {
                        delay(1500)
                        refreshStations()
                    } else if (payload.isOffline) {
                        refreshStations()
                    }
                }
                .onFailure { _errorMessage.value = "Impossible de charger les stations." }
        }
    }

    fun refreshStations() {
        viewModelScope.launch {
            runCatching { repository.refreshStations() }
                .onSuccess { payload ->
                    _stations.value = payload.data
                    updateOfflineState(payload)
                }
                .onFailure { _errorMessage.value = "Impossible de rafraichir les stations." }
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
                    updateOfflineState(payload)
                }
                .onFailure { _errorMessage.value = "Erreur reseau lors du rafraichissement." }
            _isLoading.value = false
        }
    }

    fun refreshFenetres() {
        viewModelScope.launch {
            runCatching { repository.refreshFenetres() }
                .onSuccess { payload ->
                    _fenetres.value = payload.data
                    updateOfflineState(payload)
                }
                .onFailure { _errorMessage.value = "Erreur reseau lors du rafraichissement des fenetres." }
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }

    fun loadDetail(satelliteId: String) {
        viewModelScope.launch {
            _isDetailLoading.value = true
            runCatching { repository.getSatelliteDetail(satelliteId) }
                .onSuccess { _selectedDetail.value = it }
                .onFailure { _errorMessage.value = "Impossible de charger le detail du satellite." }
            _isDetailLoading.value = false
        }
    }

    fun clearDetail() {
        _selectedDetail.value = null
    }

    fun getStationName(codeStation: String): String =
        stations.value.firstOrNull { it.codeStation == codeStation }?.nomStation ?: codeStation

    fun validatePlanningInput(satelliteId: String, stationCode: String, dureeSecondes: Int) {
        val satellite = satellites.value.firstOrNull { it.idSatellite == satelliteId }
        val station = stations.value.firstOrNull { it.codeStation == stationCode }
        _planningValidationMessage.value = repository
            .validateFenetreCreation(satellite, station, dureeSecondes)
            .message ?: "Validation OK : fenetre planifiable"
    }

    fun createPlanningFenetre(satelliteId: String, stationCode: String, dureeSecondes: Int) {
        viewModelScope.launch {
            val satellite = satellites.value.firstOrNull { it.idSatellite == satelliteId }
            val station = stations.value.firstOrNull { it.codeStation == stationCode }
            val validation = repository.validateFenetreCreation(satellite, station, dureeSecondes)
            if (!validation.isValid) {
                _planningValidationMessage.value = validation.message
                return@launch
            }

            val newFenetre = FenetreCom(
                idFenetre = nextLocalFenetreId(),
                datetimeDebut = LocalDateTime.now().plusMinutes(15),
                dureeSecondes = dureeSecondes,
                elevationMax = 0.0,
                statut = StatutFenetre.PLANIFIEE,
                idSatellite = satelliteId,
                codeStation = stationCode,
                volumeDonnees = null
            )
            val updatedFenetres = (_fenetres.value + newFenetre).sortedBy { it.datetimeDebut }
            _fenetres.value = updatedFenetres
            _selectedStationCode.value = stationCode
            runCatching { repository.saveLocalFenetre(newFenetre) }
                .onSuccess {
                    _planningValidationMessage.value = "Fenetre creee localement et ajoutee au planning"
                }
                .onFailure {
                    _planningValidationMessage.value = "Fenetre ajoutee au planning, mais non sauvegardee en cache local"
                }
        }
    }

    fun clearPlanningMessage() {
        _planningValidationMessage.value = null
    }

    fun clearMockDataWarning() {
        _mockDataWarning.value = null
    }

    fun getOperationalCountLabel(): String {
        val operational = satellites.value.count { it.statut == StatutSatellite.OPERATIONNEL }
        return "$operational/${satellites.value.size} satellites operationnels"
    }

    fun getResultCountLabel(): String = "${filteredSatellites.value.size} resultat(s)"

    fun getAllSatelliteIds(): List<String> = satellites.value.map { it.idSatellite }

    private fun nextLocalFenetreId(): Int =
        ((_fenetres.value.maxOfOrNull { it.idFenetre } ?: 0) + 1).coerceAtLeast(10_000)

    private fun updateOfflineState(payload: RepositoryPayload<*>) {
        if (payload.usesMockData) {
            _isOfflineMode.value = true
            _cacheAgeLabel.value = null
            _mockDataWarning.value =
                "Connexion a la base locale impossible et aucun cache local disponible. L'application utilise des donnees mockees."
            return
        }

        if (!payload.isOffline) {
            lastSyncAgeMinutes = 0L
            _isOfflineMode.value = false
            _cacheAgeLabel.value = null
            _mockDataWarning.value = null
            return
        }

        val wasAlreadyOffline = _isOfflineMode.value
        _isOfflineMode.value = true
        payload.cacheAgeMinutes?.let { age ->
            lastSyncAgeMinutes = if (wasAlreadyOffline) minOf(lastSyncAgeMinutes ?: age, age) else age
        }
        _cacheAgeLabel.value = repository.formatLastSyncAge(lastSyncAgeMinutes)
        _mockDataWarning.value = null
    }
}
