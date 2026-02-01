import 'package:flutter/material.dart';
import '../../models/crisis_plan.dart';
import 'dart:math';

/// Bottom sheet para añadir contacto de emergencia
class AddContactBottomSheet extends StatefulWidget {
  final bool isProfessional;

  const AddContactBottomSheet({super.key, this.isProfessional = false});

  @override
  State<AddContactBottomSheet> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends State<AddContactBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isPrimary = false;
  bool _isHealthcareProfessional = false;

  @override
  void initState() {
    super.initState();
    _isHealthcareProfessional = widget.isProfessional;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final contact = CrisisContact(
        id: '${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(10000)}',
        name: _nameController.text,
        relationship: _relationshipController.text,
        phone: _phoneController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        isPrimary: _isPrimary,
        isHealthcareProfessional: _isHealthcareProfessional,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        order: _isPrimary ? 0 : 1,
      );

      Navigator.pop(context, contact);
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
                  Text(
                    widget.isProfessional
                        ? 'Añadir Profesional'
                        : 'Añadir Contacto',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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

              // Relación
              TextFormField(
                controller: _relationshipController,
                decoration: InputDecoration(
                  labelText: widget.isProfessional ? 'Especialidad *' : 'Relación *',
                  prefixIcon: const Icon(Icons.work),
                  border: const OutlineInputBorder(),
                  hintText: widget.isProfessional
                      ? 'Ej: Psiquiatra, Psicólogo'
                      : 'Ej: Esposo/a, Madre, Amigo',
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Teléfono
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono *',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Email (opcional)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Checkboxes
              CheckboxListTile(
                title: const Text('Es contacto principal'),
                subtitle: const Text('Se mostrará primero'),
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value ?? false),
              ),
              
              if (!widget.isProfessional)
                CheckboxListTile(
                  title: const Text('Es profesional de salud'),
                  value: _isHealthcareProfessional,
                  onChanged: (value) =>
                      setState(() => _isHealthcareProfessional = value ?? false),
                ),
              const SizedBox(height: 8),

              // Notas (opcional)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  hintText: 'Cuándo llamar, instrucciones especiales...',
                ),
                maxLines: 2,
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
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
