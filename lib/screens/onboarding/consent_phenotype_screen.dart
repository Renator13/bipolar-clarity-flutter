import 'package:flutter/material.dart';
import '../../utils/app_router.dart';

/// Pantalla de consentimiento para Digital Phenotyping
/// Texto persuasivo explicando los beneficios de participar
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreeToShare = false;
  bool _readPrivacyPolicy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayúdanos a ayudarte'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icono
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF20C997).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 40,
                      color: Color(0xFF20C997),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu participación puede salvar vidas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Texto persuasivo
            _buildSection(
              title: '🔮 Predicción Temprana',
              content: 'Al compartir datos anónimos sobre tus patrones de sueño, actividad y uso del teléfono, '
                  'nuestro sistema puede detectar señales tempranas de cambios de estado hasta **varios días antes** de que sean visibles.',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '🚨 Alerta Anticipada',
              content: 'Cuando detectemos un posible riesgo de crisis, te notificaremos (y a tus contactos de confianza si tú lo decides) '
                  'con suficiente tiempo para tomar medidas preventivas.',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '🔬 Investigación Real',
              content: 'Tus datos anónimos contribuyen a investigar patrones de bipolaridad a gran escala. '
                  'Lo que aprendamos de ti puede ayudar a miles de personas en el futuro.',
            ),
            const SizedBox(height: 16),

            _buildSection(
              title: '🛡️ Total Privacidad',
              content: 'Tus datos son 100% anónimos. Usamos un ID aleatorio que no está vinculado a tu email, nombre ni ningún dato personal. '
                  'Nadie puede identificarte en nuestra base de datos de investigación.',
            ),
            const SizedBox(height: 24),

            // Checkboxes de consentimiento
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text(
                      'Quiero participar en la investigación de patrones de bipolaridad',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _agreeToShare,
                    onChanged: (value) => setState(() => _agreeToShare = value ?? false),
                    activeColor: const Color(0xFF004B49),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: Row(
                      children: [
                        const Text(
                          'He leído y acepto la ',
                          style: TextStyle(fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navegar a política de privacidad
                            Navigator.pushNamed(context, RouteNames.settings);
                          },
                          child: const Text(
                            'Política de Privacidad',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF004B49),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    value: _readPrivacyPolicy,
                    onChanged: (value) => setState(() => _readPrivacyPolicy = value ?? false),
                    activeColor: const Color(0xFF004B49),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Nota sobre retirarse
            Text(
              'Puedes retirarte en cualquier momento desde Configuración > Privacidad.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Botón continuar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canContinue() ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004B49),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opcional: botón de skip
            if (_canContinue())
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _handleSkip,
                  child: const Text('Prefiero no participar ahora'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF004B49).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF004B49).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004B49),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    return _agreeToShare && _readPrivacyPolicy;
  }

  void _handleContinue() {
    // Devolver true (consentimiento dado)
    Navigator.pop(context, true);
  }

  void _handleSkip() {
    // Devolver false (no participa)
    Navigator.pop(context, false);
  }
}
