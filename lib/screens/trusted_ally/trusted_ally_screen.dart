import 'package:flutter/material.dart';
import '../../models/trusted_ally.dart';
import '../../services/trusted_ally_service.dart';
import 'add_ally_bottom_sheet.dart';
import 'ally_settings_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de gestión de Trusted Allies
class TrustedAllyScreen extends StatefulWidget {
  const TrustedAllyScreen({super.key});

  @override
  State<TrustedAllyScreen> createState() => _TrustedAllyScreenState();
}

class _TrustedAllyScreenState extends State<TrustedAllyScreen> {
  List<TrustedAlly> _allies = [];
  bool _isLoading = true;
  final String _currentUserId = 'current_user_id'; // TODO: Obtener de Auth

  @override
  void initState() {
    super.initState();
    _loadAllies();
  }

  Future<void> _loadAllies() async {
    setState(() => _isLoading = true);
    final allies = await TrustedAllyService.getAllies(_currentUserId);
    setState(() {
      _allies = allies;
      _isLoading = false;
    });
  }

  Future<void> _addAlly() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddAllyBottomSheet(),
    );

    if (result != null && result is TrustedAlly) {
      final success = await TrustedAllyService.addAlly(result);
      if (success) _loadAllies();
    }
  }

  Future<void> _editAlly(TrustedAlly ally) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AllySettingsBottomSheet(ally: ally),
    );

    if (result != null && result is TrustedAlly) {
      final success = await TrustedAllyService.updateAllySettings(
        result.id,
        result.notificationSettings,
      );
      if (success) _loadAllies();
    }
  }

  Future<void> _removeAlly(TrustedAlly ally) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar aliado'),
        content: Text('¿Estás seguro de eliminar a ${ally.allyName} de tus contactos de confianza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await TrustedAllyService.removeAlly(_currentUserId, ally.id);
      if (success) _loadAllies();
    }
  }

  void _callAlly(String phone) {
    launchUrl(Uri.parse('tel:$phone'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactos de Confianza'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addAlly,
            tooltip: 'Añadir aliado',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allies.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allies.length,
                  itemBuilder: (context, index) => _buildAllyCard(_allies[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlly,
        icon: const Icon(Icons.person_add),
        label: const Text('Añadir'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin contactos de confianza',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade personas de confianza que recibirán\nnotificaciones cuando tu estado cambie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addAlly,
              icon: const Icon(Icons.person_add),
              label: const Text('Añadir primer contacto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004B49),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllyCard(TrustedAlly ally) {
    final statusColor = switch (ally.status) {
      AllyStatus.active => Colors.green,
      AllyStatus.pending => Colors.orange,
      AllyStatus.paused => Colors.grey,
      AllyStatus.blocked => Colors.red,
    };

    final trustIcon = switch (ally.trustLevel) {
      TrustLevel.low => Icons.shield_outlined,
      TrustLevel.medium => Icons.shield,
      TrustLevel.high => Icons.shield,
      TrustLevel.maximum => Icons.shield,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF004B49).withOpacity(0.1),
                  child: Text(
                    (ally.allyName ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004B49),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ally.allyName ?? 'Contacto sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(trustIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            ally.status == AllyStatus.pending
                                ? 'Pendiente de aceptar'
                                : '${ally.trustLevel.name} confianza',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ally.status.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Notification settings preview
            Row(
              children: [
                _buildNotificationChip('Estable', ally.notificationSettings.notifyOnStable),
                const SizedBox(width: 8),
                _buildNotificationChip('Alerta', ally.notificationSettings.notifyOnWarning),
                const SizedBox(width: 8),
                _buildNotificationChip('Emergencia', ally.notificationSettings.notifyOnCrisis),
              ],
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (ally.allyPhone != null && ally.status == AllyStatus.active)
                  TextButton.icon(
                    onPressed: () => _callAlly(ally.allyPhone!),
                    icon: const Icon(Icons.phone),
                    label: const Text('Llamar'),
                  ),
                TextButton.icon(
                  onPressed: () => _editAlly(ally),
                  icon: const Icon(Icons.settings),
                  label: const Text('Configurar'),
                ),
                TextButton.icon(
                  onPressed: () => _removeAlly(ally),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationChip(String label, bool enabled) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: enabled ? Colors.green : Colors.grey,
        ),
      ),
      backgroundColor: (enabled ? Colors.green : Colors.grey).withOpacity(0.1),
      side: BorderSide(
        color: enabled ? Colors.green : Colors.grey,
      ),
    );
  }
}
