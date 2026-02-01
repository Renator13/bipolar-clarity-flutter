import 'package:flutter/material.dart';
import '../../models/trusted_ally.dart';
import 'dart:math';

/// Bottom sheet para añadir nuevo aliado de confianza
class AddAllyBottomSheet extends StatefulWidget {
  const AddAllyBottomSheet({super.key});

  @override
  State<AddAllyBottomSheet> createState() => _AddAllyBottomSheetState();
}

class _AddAllyBottomSheetState extends State<AddAllyBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  TrustLevel _trustLevel = TrustLevel.medium;
  bool _notifyWarning = true;
  bool _notifyElevated = true;
  bool _notifyHighRisk = true;
  bool _notifyCrisis = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final ally = TrustedAlly(
        id: '${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(10000)}',
        userId: 'current_user_id', // TODO: Obtener de Auth
        allyId: _emailController.text, // Usar email como ID único
        allyName: _nameController.text,
        allyEmail: _emailController.text,
        allyPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        trustLevel: _trustLevel,
        status: AllyStatus.pending, // Pendiente hasta que acepte
        notificationSettings: NotificationSettings(
          notifyOnWarning: _notifyWarning,
          notifyOnElevated: _notifyElevated,
          notifyOnHighRisk: _notifyHighRisk,
          notifyOnCrisis: _notifyCrisis,
        ),
        createdAt: DateTime.now(),
        lastNotifiedAt: null,
      );

      Navigator.pop(context, ally);
    }
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Añadir Contacto de Confianza',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Esta persona recibirá notificaciones cuando tu estado de ánimo cambie.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Nombre
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return 'Obligatorio';
                  if (!value.contains('@')) return 'Email no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Teléfono (opcional)
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

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
              const SizedBox(height: 8),
              Text(
                _getTrustLevelDescription(_trustLevel),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Notificaciones
              const Text(
                'Notificaciones',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Señales de advertencia'),
                value: _notifyWarning,
                onChanged: (value) => setState(() => _notifyWarning = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Estado elevado (hipomanía)'),
                value: _notifyElevated,
                onChanged: (value) => setState(() => _notifyElevated = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Alto riesgo'),
                value: _notifyHighRisk,
                onChanged: (value) => setState(() => _notifyHighRisk = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Emergencia'),
                value: _notifyCrisis,
                onChanged: (value) => setState(() => _notifyCrisis = value ?? true),
              ),
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
                      child: const Text('Enviar invitación'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTrustLevelDescription(TrustLevel level) {
    switch (level) {
      case TrustLevel.low:
        return 'Solo notificaciones básicas';
      case TrustLevel.medium:
        return 'Notificaciones estándar';
      case TrustLevel.high:
        return 'Notificaciones urgentes + llamada';
      case TrustLevel.maximum:
        return 'Acceso completo + emergencia inmediata';
    }
  }
}
