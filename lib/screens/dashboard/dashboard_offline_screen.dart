import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/offline_service.dart';
import 'services/connectivity_service.dart';
import 'services/firestore_service.dart';
import 'models/mood_entry.dart';

/// Pantalla principal con soporte offline
class DashboardOfflineScreen extends StatefulWidget {
  const DashboardOfflineScreen({super.key});

  @override
  State<DashboardOfflineScreen> createState() => _DashboardOfflineScreenState();
}

class _DashboardOfflineScreenState extends State<DashboardOfflineScreen> {
  bool _isOnline = true;
  int _pendingCount = 0;
  DateTime? _lastSync;
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Usar connectivity_plus directamente
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        _syncPendingData();
      }
    });
    
    // Verificar estado inicial
    final initialResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = initialResult != ConnectivityResult.none;
    });
    
    _loadOfflineStatus();
  }

  Future<void> _loadOfflineStatus() async {
    final pending = await OfflineService.getPendingCount();
    final lastSync = await OfflineService.getLastSync();
    
    setState(() {
      _pendingCount = pending;
      _lastSync = lastSync;
    });
  }

  Future<void> _syncPendingData() async {
    if (!_isOnline) return;

    // Sincronizar entradas de humor pendientes
    final offlineEntries = await OfflineService.getOfflineEntries();
    for (final entry in offlineEntries) {
      await FirestoreService.saveMoodEntry(entry);
    }
    
    await OfflineService.clearPendingSync();
    await _loadOfflineStatus();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${offlineEntries.length} entradas sincronizadas'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _saveOffline() async {
    // Guardar dato offline
    final entry = MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user_id',
      moodScore: 5.0,
      date: DateTime.now(),
      notes: 'Guardado offline',
    );
    
    await OfflineService.saveMoodEntryOffline(entry);
    await _loadOfflineStatus();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guardado localmente (se sincronizará cuando haya conexión)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bipolar Clarity'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
        actions: [
          // Indicador de estado
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              label: Text(
                _isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: _isOnline ? Colors.white : Colors.white70,
                  fontSize: 12,
                ),
              ),
              backgroundColor: _isOnline ? Colors.green : Colors.orange,
              avatar: Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de sincronización pendiente
          if (_pendingCount > 0 && _isOnline)
            _buildSyncBanner(),
          
          // Banner offline
          if (!_isOnline)
            _buildOfflineBanner(),

          // Contenido principal
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón de prueba guardar offline
                  ElevatedButton.icon(
                    onPressed: _saveOffline,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar (Test Offline)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004B49),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estado actual
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.sync),
                            title: const Text('Estado de sincronización'),
                            subtitle: _lastSync != null
                                ? Text('Última: ${_lastSync!.hour}:${_lastSync!.minute.toString().padLeft(2, '0')}')
                                : const Text('Sin sincronizar'),
                          ),
                          if (_pendingCount > 0)
                            ListTile(
                              leading: const Icon(Icons.cloud_upload, color: Colors.orange),
                              title: Text('$_pendingCount entradas pendientes'),
                              subtitle: const Text('Se sincronizarán al volver a estar online'),
                              trailing: _isOnline
                                  ? TextButton(
                                      onPressed: _syncPendingData,
                                      child: const Text('Sincronizar ahora'),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange[100],
      child: Row(
        children: [
          const Icon(Icons.cloud_upload, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos pendientes de sincronizar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_pendingCount entradas guardadas localmente',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (_isOnline)
            ElevatedButton(
              onPressed: _syncPendingData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sincronizar'),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red[100],
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.red),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sin conexión a internet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
