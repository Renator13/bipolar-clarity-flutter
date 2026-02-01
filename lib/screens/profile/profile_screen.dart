import 'package:flutter/material.dart';
import '../../services/theme_service.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';
import 'edit_profile_bottom_sheet.dart';
import 'settings_screen.dart';

/// Pantalla de perfil del usuario
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String _themeMode = 'Sistema';
  final String _currentUserId = 'current_user_id'; // TODO: Obtener de Auth

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadThemeMode();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    // Cargar usuario (simulado)
    final user = User(
      id: _currentUserId,
      email: 'rené@ejemplo.com',
      name: 'René Dechamps Otamendi',
      createdAt: DateTime.now(),
    );
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _loadThemeMode() async {
    final mode = await ThemeService.getModeName();
    setState(() => _themeMode = mode);
  }

  Future<void> _editProfile() async {
    if (_user == null) return;
    
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProfileBottomSheet(user: _user!),
    );

    if (result != null && result is User) {
      setState(() => _user = result);
    }
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: const Color(0xFF004B49),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Configuración',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar grande
                  _buildAvatar(),
                  const SizedBox(height: 24),

                  // Info del usuario
                  _buildUserInfo(),
                  const SizedBox(height: 24),

                  // Opciones del perfil
                  _buildProfileOptions(),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: const Color(0xFF004B49),
      child: Text(
        (_user?.name ?? 'U')[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _user?.name ?? 'Usuario',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _user?.email ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Editar perfil'),
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

  Widget _buildProfileOptions() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Tema de la app'),
            subtitle: Text(_themeMode),
            onTap: _showThemeDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacidad y términos'),
            subtitle: const Text('Términos de uso y política de privacidad'),
            onTap: _navigateToSettings,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ayuda'),
            subtitle: const Text('Preguntas frecuentes y soporte'),
            onTap: () {}, // TODO
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            subtitle: const Text('Versión de la app'),
            onTap: () {}, // TODO
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema de la app'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Claro', ThemeMode.light),
            _buildThemeOption('Oscuro', ThemeMode.dark),
            _buildThemeOption('Sistema', ThemeMode.system),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String title, ThemeMode mode) {
    return ListTile(
      title: Text(title),
      trailing: _themeMode == title ? const Icon(Icons.check, color: Color(0xFF004B49)) : null,
      onTap: () async {
        await ThemeService.setThemeMode(mode);
        await _loadThemeMode();
        if (mounted) Navigator.pop(context);
      },
    );
  }
}
