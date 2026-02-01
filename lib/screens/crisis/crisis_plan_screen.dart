import 'package:flutter/material.dart';
import '../../models/crisis_plan.dart';
import '../../services/crisis_plan_service.dart';
import '../../services/firestore_service.dart';
import 'add_contact_bottom_sheet.dart';
import 'edit_section_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla del Plan de Crisis / Safety Plan
class CrisisPlanScreen extends StatefulWidget {
  const CrisisPlanScreen({super.key});

  @override
  State<CrisisPlanScreen> createState() => _CrisisPlanScreenState();
}

class _CrisisPlanScreenState extends State<CrisisPlanScreen> {
  CrisisPlan? _plan;
  bool _isLoading = true;
  final String _currentUserId = 'current_user_id'; // TODO: Obtener de Auth

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    
    // Intentar obtener plan existente o crear plantilla
    CrisisPlan? plan = await CrisisPlanService.getPlan(_currentUserId);
    plan ??= CrisisPlanService.getTemplate(_currentUserId);
    
    setState(() {
      _plan = plan;
      _isLoading = false;
    });
  }

  Future<void> _addContact(bool isProfessional) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddContactBottomSheet(isProfessional: isProfessional),
    );

    if (result != null && result is CrisisContact) {
      final success = await CrisisPlanService.addEmergencyContact(_currentUserId, result);
      if (success) _loadPlan();
    }
  }

  Future<void> _editSection(String title, List<String> items, bool isList) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditSectionBottomSheet(
        title: title,
        items: items,
        isList: isList,
      ),
    );

    if (result != null && result is List<String>) {
      // Actualizar la sección correspondiente
      // TODO: Implementar actualización de secciones
      _loadPlan();
    }
  }

  void _callEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergencia'),
        content: const Text('¿Llamar al 112/911?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse('tel:112'));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan de Seguridad'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_emergency),
            onPressed: _callEmergency,
            tooltip: 'Emergencia',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de completitud
            _buildCompletenessIndicator(),
            const SizedBox(height: 20),

            // Contactos de emergencia
            _buildSection(
              title: 'Contactos de Emergencia',
              icon: Icons.contact_phone,
              items: _plan!.emergencyContacts.map((c) => '${c.name} - ${c.relationship}').toList(),
              isEmpty: _plan!.emergencyContacts.isEmpty,
              onAdd: () => _addContact(false),
              onEdit: () => _editSection('Contactos', [], false),
            ),
            const SizedBox(height: 16),

            // Señales de advertencia
            _buildSection(
              title: 'Señales de Advertencia',
              subtitle: 'Qué me avisa de que algo no va bien',
              icon: Icons.warning_amber,
              items: _plan!.warningSigns,
              onAdd: () => _editSection('Señales de Advertencia', _plan!.warningSigns, true),
              onEdit: () => _editSection('Señales de Advertencia', _plan!.warningSigns, true),
            ),
            const SizedBox(height: 16),

            // Estrategias de afrontamiento
            _buildSection(
              title: 'Estrategias de Afrontamiento',
              subtitle: 'Qué puedo hacer para sentirme mejor',
              icon: Icons.self_improvement,
              items: _plan!.copingStrategies,
              onAdd: () => _editSection('Estrategias', _plan!.copingStrategies, true),
              onEdit: () => _editSection('Estrategias', _plan!.copingStrategies, true),
            ),
            const SizedBox(height: 16),

            // Cambios ambientales
            _buildSection(
              title: 'Cambios Ambientales',
              subtitle: 'Qué puedo cambiar en mi entorno',
              icon: Icons.home,
              items: _plan!.environmentalChanges,
              onAdd: () => _editSection('Cambios Ambientales', _plan!.environmentalChanges, true),
              onEdit: () => _editSection('Cambios Ambientales', _plan!.environmentalChanges, true),
            ),
            const SizedBox(height: 16),

            // Contactos sociales
            _buildSection(
              title: 'Contactos Sociales',
              subtitle: 'Personas que pueden distraerme',
              icon: Icons.people,
              items: _plan!.socialContacts,
              onAdd: () => _editSection('Contactos Sociales', _plan!.socialContacts, true),
              onEdit: () => _editSection('Contactos Sociales', _plan!.socialContacts, true),
            ),
            const SizedBox(height: 16),

            // Recursos profesionales
            _buildSection(
              title: 'Recursos Profesionales',
              subtitle: 'Ayuda profesional disponible',
              icon: Icons.medical_services,
              items: _plan!.professionalResources,
              onAdd: () => _addContact(true),
              onEdit: () => _editSection('Recursos Profesionales', _plan!.professionalResources, true),
            ),
            const SizedBox(height: 30),

            // Botón de emergencia grande
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _callEmergency,
                icon: const Icon(Icons.phone, size: 24),
                label: const Text('LLAMAR A EMERGENCIAS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletenessIndicator() {
    final complete = CrisisPlanService.isPlanComplete(_plan!);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: complete ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complete ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            complete ? Icons.check_circle : Icons.info,
            color: complete ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              complete
                  ? 'Tu plan de seguridad está completo'
                  : 'Completa tu plan para estar preparado',
              style: TextStyle(
                color: complete ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required IconData icon,
    required List<String> items,
    required VoidCallback onAdd,
    required VoidCallback onEdit,
    bool isEmpty = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF004B49)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (subtitle != null)
                        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: items.isEmpty ? onAdd : onEdit,
                  icon: Icon(items.isEmpty ? Icons.add : Icons.edit, size: 18),
                  label: Text(items.isEmpty ? 'Añadir' : 'Editar'),
                ),
              ],
            ),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Sin ${title.toLowerCase()}',
                  style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: items.take(5).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, left: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
