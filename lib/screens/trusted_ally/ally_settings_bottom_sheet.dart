import 'package:flutter/material.dart';
import '../../models/trusted_ally.dart';

/// Bottom sheet para configurar notificaciones de un aliado
class AllySettingsBottomSheet extends StatefulWidget {
  final TrustedAlly ally;

  const AllySettingsBottomSheet({super.key, required this.ally});

  @override
  State<AllySettingsBottomSheet> createState() => _AllySettingsBottomSheetState();
}

class _AllySettingsBottomSheetState extends State<AllySettingsBottomSheet> {
  late NotificationSettings _settings;
  late TrustLevel _trustLevel;
  late AllyStatus _status;

  @override
  void initState() {
    super.initState();
    _settings = widget.ally.notificationSettings;
    _trustLevel = widget.ally.trustLevel;
    _status = widget.ally.status;
  }

  void _save() {
    final updatedAlly = widget.ally.copyWith(
      trustLevel: _trustLevel,
      status: _status,
      notificationSettings: _settings,
    );
    Navigator.pop(context, updatedAlly);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Configurar: ${widget.ally.allyName}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Estado
            const Text(
              'Estado',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AllyStatus>(
              segments: const [
                ButtonSegment(value: AllyStatus.active, label: Text('Activo')),
                ButtonSegment(value: AllyStatus.paused, label: Text('Pausado')),
                ButtonSegment(value: AllyStatus.blocked, label: Text('Bloqueado')),
              ],
              selected: {_status},
              onSelectionChanged: (Set<AllyStatus> newSelection) {
                setState(() => _status = newSelection.first);
              },
            ),
            const SizedBox(height: 16),

            // Nivel de confianza
            const Text(
              'Nivel de confianza',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<TrustLevel>(
              segments: const [
                ButtonSegment(value: TrustLevel.low, label: Text('Bajo')),
                ButtonSegment(value: TrustLevel.medium, label: Text('Medio')),
                ButtonSegment(value: TrustLevel.high, label: Text('Alto')),
                ButtonSegment(value: TrustLevel.maximum, label: Text('Máximo')),
              ],
              selected: {_trustLevel},
              onSelectionChanged: (Set<TrustLevel> newSelection) {
                setState(() => _trustLevel = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            // Notificaciones por tipo
            const Text(
              'Notificar cuando detecte:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Estado estable'),
              subtitle: const Text('Todo va bien'),
              value: _settings.notifyOnStable,
              onChanged: (value) => setState(() => _settings.notifyOnStable = value),
              activeColor: Colors.green,
            ),
            SwitchListTile(
              title: const Text('Señales de advertencia'),
              subtitle: const Text('Cambios que merecen atención'),
              value: _settings.notifyOnWarning,
              onChanged: (value) => setState(() => _settings.notifyOnWarning = value),
              activeColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text('Estado elevado'),
              subtitle: const Text('Posible hipomanía'),
              value: _settings.notifyOnElevated,
              onChanged: (value) => setState(() => _settings.notifyOnElevated = value),
              activeColor: Colors.orange,
            ),
            SwitchListTile(
              title: const Text('Alto riesgo'),
              subtitle: const Text('Necesita atención'),
              value: _settings.notifyOnHighRisk,
              onChanged: (value) => setState(() => _settings.notifyOnHighRisk = value),
              activeColor: Colors.red,
            ),
            SwitchListTile(
              title: const Text('Emergencia'),
              subtitle: const Text('Crisis activa'),
              value: _settings.notifyOnCrisis,
              onChanged: (value) => setState(() => _settings.notifyOnCrisis = value),
              activeColor: Colors.red[700],
            ),
            const SizedBox(height: 24),

            // Llamada automática
            const Text(
              'Llamada automática',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Permitir llamada automática'),
              subtitle: const Text('Llamar automáticamente en emergencia'),
              value: _settings.allowCall,
              onChanged: (value) => setState(() => _settings.allowCall = value),
              activeColor: Colors.red,
            ),
            if (_settings.allowCall) ...[
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Minutos antes de llamar',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _settings.callDelayMinutes.toString(),
                onChanged: (value) {
                  _settings.callDelayMinutes = int.tryParse(value) ?? 0;
                },
              ),
            ],
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004B49),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
