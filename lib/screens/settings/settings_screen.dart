import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

/// Pantalla de configuración general (accesible desde el perfil)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: General
            _buildSectionTitle('General'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Notificaciones push'),
                    subtitle: const Text('Recibir alertas sobre tu estado'),
                    value: _notificationsEnabled,
                    onChanged: (value) => setState(() => _notificationsEnabled = value),
                    activeColor: const Color(0xFF004B49),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Sincronización automática'),
                    subtitle: const Text('Guardar datos automáticamente'),
                    value: _autoSyncEnabled,
                    onChanged: (value) => setState(() => _autoSyncEnabled = value),
                    activeColor: const Color(0xFF004B49),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sección: Legal
            _buildSectionTitle('Legal'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Términos de uso'),
                    subtitle: const Text('Condiciones del servicio'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTermsOfService(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('Política de privacidad'),
                    subtitle: const Text('Cómo protegemos tus datos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrivacyPolicy(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cookie),
                    title: const Text('Política de cookies'),
                    subtitle: const Text('Uso de cookies y tracking'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showCookiePolicy(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sección: Acciones
            _buildSectionTitle('Cuenta'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Exportar datos'),
                    subtitle: const Text('Descargar tus datos personales'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {}, // TODO
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Eliminar cuenta'),
                    subtitle: const Text('Borrar permanentemente todos los datos'),
                    textColor: Colors.red,
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () => _confirmDeleteAccount(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Versión
            Center(
              child: Text(
                'Bipolar Clarity v1.0.0',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF004B49),
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LegalDocumentScreen(
        title: 'Términos de Uso',
        content: _termsOfServiceContent,
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LegalDocumentScreen(
        title: 'Política de Privacidad',
        content: _privacyPolicyContent,
      ),
    );
  }

  void _showCookiePolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const LegalDocumentScreen(
        title: 'Política de Cookies',
        content: _cookiePolicyContent,
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          '¿Estás seguro? Esta acción es irreversible y se eliminarán permanentemente todos tus datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar eliminación de cuenta
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

/// Pantalla para mostrar documentos legales
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}

// Términos de uso
const String _termsOfServiceContent = '''
TÉRMINOS DE USO DE BIPOLAR CLARITY

Última actualización: Febrero 2026

1. ACEPTACIÓN DE TÉRMINOS
Al descargar y utilizar Bipolar Clarity, aceptas estos términos de uso.

2. DESCRIPCIÓN DEL SERVICIO
Bipolar Clarity es una aplicación de seguimiento del estado de ánimo diseñada para personas con trastorno bipolar. No sustituye la atención médica profesional.

3. USO DEL SERVICIO
- Debes ser mayor de edad para usar esta aplicación
- Los datos que registras son responsabilidad tuya
- No uses la app en situaciones de emergencia médica

4. LIMITACIÓN DE RESPONSABILIDAD
- No somos responsables de decisiones médicas que tomes basándote en la app
- Siempre consulta con profesionales de salud cualificados
- La app no sustituye el tratamiento médico

5. PRIVACIDAD
Tu privacidad es importante. Consulta nuestra Política de Privacidad para saber cómo protegemos tus datos.

6. MODIFICACIONES
Podemos modificar estos términos. Te notificaremos de cambios importantes.

7. CONTACTO
Para preguntas sobre estos términos: soporte@bipolarclarity.com
''';

// Política de privacidad
const String _privacyPolicyContent = '''
POLÍTICA DE PRIVACIDAD DE BIPOLAR CLARITY

Última actualización: Febrero 2026

1. INFORMACIÓN QUE RECOPILAMOS
- Datos de registro de humor
- Patrones de sueño
- Información de la cuenta (email, nombre)
- Datos de uso de la app

2. CÓMO USAMOS TUS DATOS
- Proporcionar el servicio de seguimiento del estado de ánimo
- Mejorar la experiencia del usuario
- Notificar a contactos de confianza si lo autorizas

3. ALMACENAMIENTO DE DATOS
- Tus datos se almacenan de forma segura en servidores cifrados
- Puedes solicitar la eliminación de tus datos en cualquier momento
- Los datos se procesan según las normativas GDPR

4. TUS DERECHOS
- Derecho a acceder a tus datos
- Derecho a rectificar datos incorrectos
- Derecho a eliminar tus datos
- Derecho a exportar tus datos

5. COMPARTICIÓN DE DATOS
- No vendemos tus datos personales
- Solo compartimos datos con tu consentimiento explícito
- Con contactos de confianza si tú lo autorizas

6. CONTACTO
Para ejercer tus derechos: privacidad@bipolarclarity.com
''';

// Política de cookies
const String _cookiePolicyContent = '''
POLÍTICA DE COOKIES DE BIPOLAR CLARITY

Última actualización: Febrero 2026

1. QUÉ SON LAS COOKIES
Las cookies son pequeños archivos de texto que se almacenan en tu dispositivo.

2. COOKIES QUE UTILIZAMOS
- Cookies esenciales: necesarias para el funcionamiento de la app
- Cookies de preferencias: recordar tu tema (claro/oscuro)
- Cookies analíticas: entender cómo usas la app

3. GESTIONAR COOKIES
Puedes desactivar las cookies en la configuración de tu navegador.

4. DATOS ALMACENADOS LOCALMENTE
La app almacena datos localmente para funcionar sin conexión:
- Registros de humor
- Configuración de preferencias
- Datos del plan de seguridad

5. CONTACTO
Para preguntas sobre cookies: cookies@bipolarclarity.com
''';
