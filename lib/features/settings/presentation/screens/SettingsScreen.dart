import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/widgets/AppScaffold.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';
import 'package:mecanaut_mobile/features/settings/data/models/local_settings.dart';
import 'package:mecanaut_mobile/features/settings/data/services/LocalSettingsStorage.dart';
import 'package:mecanaut_mobile/features/settings/data/services/ProfileService.dart';
import 'package:mecanaut_mobile/features/settings/data/services/SettingsService.dart';
import 'package:mecanaut_mobile/features/settings/presentation/controllers/SettingsController.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late final SettingsController _controller;
  late final TabController _tabController;
  final _companyController = TextEditingController(text: 'CompanyName');
  final _rucController = TextEditingController(text: '1234568778');
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(text: '********');
  final _deleteReasonController = TextEditingController();

  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _billingEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final Dio dio = ref.read(apiDioProvider);
    _controller = SettingsController(
      settingsService: SettingsService(LocalSettingsStorage()),
      profileService: ProfileService(dio),
      session: ref.read(authSessionProvider),
    );
    _tabController = TabController(length: 3, vsync: this);
    _controller.addListener(_syncControllers);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_syncControllers);
    _tabController.dispose();
    _companyController.dispose();
    _rucController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _deleteReasonController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _billingEmailController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncControllers() {
    final profile = _controller.profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName;
      _emailController.text = profile.email;
    }
    final local = _controller.localSettings;
    _cardHolderController.text = local.cardHolder;
    _cardNumberController.text = local.cardNumber;
    _cardExpiryController.text = local.cardExpiry;
    _cardCvvController.text = local.cardCvv;
    _billingEmailController.text = local.billingEmail;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return AppScaffold(
          title: 'Configuracion',
          currentRoute: '/configuracion',
          child: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) return const LoadingView(message: 'Cargando configuracion...');
    if (_controller.error != null && !_controller.hasProfile) {
      return ErrorStateView(message: _controller.error!, onRetry: _controller.load);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Configuracion',
          style: TextStyle(fontSize: 40 / 2, fontWeight: FontWeight.w700, color: Color(0xFF1F56A0)),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          tabs: const <Tab>[
            Tab(text: 'Cuenta'),
            Tab(text: 'Facturacion'),
            Tab(text: 'Eliminar'),
          ],
          labelColor: const Color(0xFF1F56A0),
          indicatorColor: const Color(0xFF5B62B3),
          unselectedLabelColor: const Color(0xFF343A48),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _buildAccountTab(),
              _buildBillingTab(),
              _buildDeleteTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab() {
    final profile = _controller.profile;
    final local = _controller.localSettings;
    return ListView(
      children: <Widget>[
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Informacion de la empresa', style: _titleStyle),
              const SizedBox(height: 12),
              const Text('Nombre'),
              TextFormField(controller: _companyController, readOnly: true),
              const SizedBox(height: 10),
              const Text('RUC'),
              TextFormField(controller: _rucController, readOnly: true),
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Informacion de la cuenta administrativa', style: _titleStyle),
              const SizedBox(height: 12),
              const Text('Nombre'),
              TextFormField(
                controller: _fullNameController,
                enabled: profile != null,
              ),
              const SizedBox(height: 10),
              const Text('Correo'),
              TextFormField(
                controller: _emailController,
                enabled: profile != null,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              const Text('Contrasena'),
              TextFormField(
                controller: _passwordController,
                readOnly: true,
                obscureText: true,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.visibility_off_outlined),
                ),
              ),
              if (profile != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  'Rol: ${profile.roles.isEmpty ? '-' : profile.roles.first}',
                  style: const TextStyle(color: Color(0xFF6E7392)),
                ),
              ],
            ],
          ),
        ),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Idiomas', style: _titleStyle),
              const SizedBox(height: 12),
              const Text('Idioma'),
              DropdownButtonFormField<AppLanguage>(
                initialValue: local.language,
                items: const <DropdownMenuItem<AppLanguage>>[
                  DropdownMenuItem(value: AppLanguage.es, child: Text('Espanol')),
                  DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _controller.saveLocal(local.copyWith(language: value));
                },
              ),
              const SizedBox(height: 10),
              const Text('Zona horaria'),
              DropdownButtonFormField<String>(
                initialValue: local.timezone,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: '(UTC-05:00)', child: Text('(UTC-05:00)')),
                  DropdownMenuItem(value: '(UTC+00:00)', child: Text('(UTC+00:00)')),
                  DropdownMenuItem(value: '(UTC+01:00)', child: Text('(UTC+01:00)')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _controller.saveLocal(local.copyWith(timezone: value));
                },
              ),
            ],
          ),
        ),
        SwitchListTile(
          value: local.notificationsEnabled,
          onChanged: (value) => _controller.saveLocal(local.copyWith(notificationsEnabled: value)),
          title: const Text('Notificaciones'),
          subtitle: const Text('Preferencia local del dispositivo'),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _controller.isSaving ? null : _saveAccount,
            child: Text(_controller.isSaving ? 'Guardando...' : 'Guardar'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _controller.isSaving ? null : _logout,
            child: const Text('Cerrar sesion'),
          ),
        ),
        if (_controller.error != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_controller.error!, style: const TextStyle(color: Color(0xFFD7465E))),
        ],
      ],
    );
  }

  Widget _buildBillingTab() {
    return ListView(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF5B62B3),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('PLAN ACTUAL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Plan Corporativo / mensual', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(child: _InfoBox(label: 'Tiempo suscrito', value: '3 meses')),
                  SizedBox(width: 10),
                  Expanded(child: _InfoBox(label: 'Siguiente pago', value: '1 Mayo, 2025')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Datos de la tarjeta', style: _titleStyle),
              const SizedBox(height: 12),
              const Text('Nombre del propietario'),
              TextFormField(controller: _cardHolderController),
              const SizedBox(height: 10),
              const Text('Numero de la tarjeta'),
              TextFormField(controller: _cardNumberController),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Fecha de vencimiento'),
                        TextFormField(controller: _cardExpiryController),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Codigo de seguridad'),
                        TextFormField(controller: _cardCvvController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('Correo electronico'),
              TextFormField(controller: _billingEmailController),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveBilling,
                  child: const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Planes que puedes adquirir', style: _titleStyle),
        const SizedBox(height: 10),
        _planCard(
          title: 'Plan Corporativo',
          subtitle: 'Para grandes empresas y flotas.',
          ctaPrimary: 'Plan Actual Activo',
          active: true,
        ),
        _planCard(
          title: 'Plan Gratuito',
          subtitle: 'Funciones basicas para iniciar.',
          ctaPrimary: 'Adquirir plan mensual',
          ctaSecondary: 'Adquirir plan anual',
        ),
        _planCard(
          title: 'Plan Profesional',
          subtitle: 'Herramientas avanzadas para pymes.',
          ctaPrimary: 'Adquirir plan mensual',
          ctaSecondary: 'Adquirir plan anual',
          tag: 'POPULAR',
        ),
      ],
    );
  }

  Widget _buildDeleteTab() {
    return ListView(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1CED6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFFF8CAD3),
                    child: Icon(Icons.warning_amber_rounded, color: Color(0xFFD7465E)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('Eliminar cuenta', style: TextStyle(color: Color(0xFFD7465E), fontSize: 32 / 2, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Esta accion es permanente y no se puede deshacer.'),
              const SizedBox(height: 14),
              const Text('Motivo'),
              const SizedBox(height: 6),
              TextField(
                controller: _deleteReasonController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Escribe tu motivo para que podamos mejorar tu proxima experiencia'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showDeleteNotAvailable,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD7465E),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Eliminar Cuenta'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pendiente: backend no expone endpoint especifico para baja de cuenta/tenant en esta app movil.',
                style: TextStyle(color: Color(0xFF8E95B8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EF)),
      ),
      child: child,
    );
  }

  Widget _planCard({
    required String title,
    required String subtitle,
    required String ctaPrimary,
    String? ctaSecondary,
    String? tag,
    bool active = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? const Color(0xFF1F56A0) : const Color(0xFFE5E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (tag != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF5B62B3), borderRadius: BorderRadius.circular(10)),
                child: Text(tag, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          Text(title, style: const TextStyle(fontSize: 34 / 2, fontWeight: FontWeight.w700)),
          Text(subtitle, style: const TextStyle(color: Color(0xFF4C4F58))),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: active ? null : () {},
              child: Text(ctaPrimary),
            ),
          ),
          if (ctaSecondary != null) ...<Widget>[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () {}, child: Text(ctaSecondary)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveAccount() async {
    final profile = _controller.profile;
    if (profile != null) {
      final ok = await _controller.saveProfile(
        fullName: _fullNameController.text,
        email: _emailController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Cuenta actualizada.' : (_controller.error ?? 'No se pudo guardar la cuenta.'))),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil no disponible para edicion.')));
    }
  }

  Future<void> _saveBilling() async {
    final local = _controller.localSettings.copyWith(
      cardHolder: _cardHolderController.text.trim(),
      cardNumber: _cardNumberController.text.trim(),
      cardExpiry: _cardExpiryController.text.trim(),
      cardCvv: _cardCvvController.text.trim(),
      billingEmail: _billingEmailController.text.trim(),
    );
    await _controller.saveLocal(local);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambios de facturacion guardados localmente.')));
  }

  Future<void> _logout() async {
    await _controller.logout();
    if (!mounted) return;
    context.go('/login');
  }

  void _showDeleteNotAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Eliminar cuenta no disponible en backend actual. Puedes cerrar sesion desde Cuenta.'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

const TextStyle _titleStyle = TextStyle(
  fontSize: 40 / 2,
  fontWeight: FontWeight.w700,
  color: Color(0xFF1F56A0),
);

