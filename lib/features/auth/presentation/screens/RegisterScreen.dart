import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/widgets/PrimaryButton.dart';
import 'package:mecanaut_mobile/features/auth/data/dtos/sign_up_request.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _rucController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _commercialNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(text: 'Lima');
  final _countryController = TextEditingController(text: 'Peru');
  final _tenantPhoneController = TextEditingController();
  final _tenantEmailController = TextEditingController();
  final _websiteController = TextEditingController();

  final _usernameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _subscriptionPlanId = 1;
  bool _acceptTerms = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  String _selectedRole = 'administrador';

  @override
  void dispose() {
    _rucController.dispose();
    _legalNameController.dispose();
    _commercialNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _tenantPhoneController.dispose();
    _tenantEmailController.dispose();
    _websiteController.dispose();
    _usernameController.dispose();
    _userEmailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authSessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8EEF8),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 26,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'Crear cuenta',
                      style: TextStyle(
                        color: Color(0xFF1F56A0),
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Estamos felices de que te unas',
                      style: TextStyle(fontSize: 18, color: Color(0xFF3D3D3D)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    title: 'Informacion de la empresa',
                    subtitle: 'Completa los datos de tu empresa para comenzar',
                    children: <Widget>[
                      _label('RUC'),
                      TextFormField(
                        controller: _rucController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '20612345678',
                        ),
                        validator: _validateRuc,
                      ),
                      const SizedBox(height: 14),
                      _label('Nombre legal'),
                      TextFormField(
                        controller: _legalNameController,
                        decoration: const InputDecoration(
                          hintText: 'Empresa Industrial S.A.C.',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _label('Nombre comercial'),
                      TextFormField(
                        controller: _commercialNameController,
                        decoration: const InputDecoration(
                          hintText: 'Mecanaut Industrial',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _label('Direccion'),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Av. Principal 123',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _label('Ciudad'),
                                TextFormField(
                                  controller: _cityController,
                                  decoration: const InputDecoration(
                                    hintText: 'Lima',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _label('Pais'),
                                TextFormField(
                                  controller: _countryController,
                                  decoration: const InputDecoration(
                                    hintText: 'Peru',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label('Telefono de la empresa'),
                      TextFormField(
                        controller: _tenantPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '+51 999 999 999',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('Correo de la empresa'),
                      TextFormField(
                        controller: _tenantEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'operaciones@empresa.com',
                        ),
                        validator: _validateEmailRequired,
                      ),
                      const SizedBox(height: 14),
                      _label('Sitio web (opcional)'),
                      TextFormField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'https://www.empresa.com',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _label('Plan de suscripcion'),
                      DropdownButtonFormField<int>(
                        initialValue: _subscriptionPlanId,
                        items: const <DropdownMenuItem<int>>[
                          DropdownMenuItem(value: 1, child: Text('Plan 1')),
                          DropdownMenuItem(value: 2, child: Text('Plan 2')),
                          DropdownMenuItem(value: 3, child: Text('Plan 3')),
                        ],
                        onChanged: (int? value) {
                          if (value != null) {
                            setState(() => _subscriptionPlanId = value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Informacion personal',
                    subtitle: 'Completa tus datos personales y selecciona tu rol',
                    children: <Widget>[
                      _label('Selecciona tu Rol'),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _roleCard(
                              role: 'administrador',
                              title: 'Administrador',
                              icon: Icons.admin_panel_settings_outlined,
                              isSelected: _selectedRole == 'administrador',
                              onTap: () => setState(() => _selectedRole = 'administrador'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _roleCard(
                              role: 'tecnico',
                              title: 'Técnico',
                              icon: Icons.engineering_outlined,
                              isSelected: _selectedRole == 'tecnico',
                              onTap: () => setState(() => _selectedRole = 'tecnico'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label('Usuario'),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'admin_empresa',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _label('Correo del usuario'),
                      TextFormField(
                        controller: _userEmailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'admin@empresa.com',
                        ),
                        validator: _validateEmailRequired,
                      ),
                      const SizedBox(height: 14),
                      _label('Nombre'),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(hintText: 'Juan'),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _label('Apellido'),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(hintText: 'Perez'),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      _label('Contrasena'),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          hintText: '********',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (value.length < 8) {
                            return 'Minimo 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _label('Repetir contrasena'),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _hideConfirm,
                        decoration: InputDecoration(
                          hintText: '********',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _hideConfirm = !_hideConfirm),
                            icon: Icon(
                              _hideConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          if (value != _passwordController.text) {
                            return 'Las contrasenas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (bool? value) {
                          setState(() => _acceptTerms = value ?? false);
                        },
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'He leido y acepto los ',
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Terminos y Condiciones',
                                style: const TextStyle(color: Color(0xFF5B62B3)),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    _showTermsDialog(context);
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (authSession.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        authSession.errorMessage!,
                        style: const TextStyle(color: Color(0xFFD7465E)),
                      ),
                    ),
                  PrimaryButton(
                    label: 'Crear cuenta',
                    isLoading: authSession.isLoading,
                    onPressed: _onSubmit,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Wrap(
                      children: <Widget>[
                        const Text('Ya tienes una cuenta? '),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text(
                            'Inicia sesion',
                            style: TextStyle(color: Color(0xFF5B62B3)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Términos y Condiciones',
            style: TextStyle(color: Color(0xFF1F56A0), fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sectionTitle('1. Definición del Servicio'),
                  _contentBody(
                      'Mecanaut es una solución de software como servicio (SaaS) que permite la gestión de activos, planificación de mantenimiento preventivo/correctivo y análisis de KPIs industriales. \nEl servicio se presta a través de una aplicación web y herramientas de visualización de datos.'),

                  _sectionTitle('2. Planes de Suscripción y Pago'),
                  _contentBody(
                      '• Plan Gratuito: Hasta 10 activos y 1 perfil de administrador.\n'
                          '• Plan Profesional: Hasta 50 activos y 5 administradores, incluyendo mantenimiento preventivo.\n'
                          '• Plan Enterprise: Activos y usuarios ilimitados con personalización avanzada.\n'
                          '• Facturación: Los pagos se realizan de forma mensual o anual según lo contratado.'),

                  _sectionTitle('3. Responsabilidades del Usuario'),
                  _contentBody(
                      '• Administradores: Son responsables de la veracidad de los datos de maquinaria e inventario.\n'
                          '• Técnicos: Responsables del registro preciso de evidencias y cierre de órdenes de trabajo.\n'
                          '• Seguridad: El usuario es responsable de la confidencialidad de sus credenciales.'),

                  _sectionTitle('4. Propiedad Intelectual y Datos'),
                  _contentBody(
                      '• Propiedad del Software: AwawaTech conserva todos los derechos sobre el código fuente y diseño.\n'
                          '• Datos del Cliente: Los datos pertenecen al cliente, pero Mecanaut tiene permiso para procesarlos para generar indicadores (MTTR, MTBF).'),

                  _sectionTitle('5. Disponibilidad y Soporte (SLA)'),
                  _contentBody(
                      'Mecanaut se compromete a mantener la plataforma operativa para garantizar la continuidad de las líneas de producción y brindará asesoría en la implementación.'),

                  _sectionTitle('6. Limitación de Responsabilidad'),
                  _contentBody(
                      'Mecanaut ayuda a optimizar procesos, pero no se hace responsable por fallas mecánicas directas o paradas de planta derivadas de una mala programación manual del cliente.'),

                  _sectionTitle('7. Terminación del Servicio'),
                  _contentBody(
                      'El cliente puede cancelar su suscripción en cualquier momento. Tendrá un periodo de 30 días para exportar su historial antes de la eliminación de datos.'),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Color(0xFF5B62B3))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F56A0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                setState(() => _acceptTerms = true);
                Navigator.pop(context);
              },
              child: const Text('Aceptar y Continuar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onSubmit() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar terminos y condiciones.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = SignUpRequest(
      ruc: _rucController.text.trim(),
      legalName: _legalNameController.text.trim(),
      commercialName: _commercialNameController.text.trim(),
      address: _orNull(_addressController),
      city: _orNull(_cityController),
      country: _orNull(_countryController),
      tenantPhone: _orNull(_tenantPhoneController),
      tenantEmail: _tenantEmailController.text.trim(),
      website: _orNull(_websiteController),
      subscriptionPlanId: _subscriptionPlanId,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      email: _userEmailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      role: _selectedRole,
    );

    final ok = await ref.read(authSessionProvider).signUp(request);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada correctamente.')),
      );
      context.go('/login');
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F56A0),
        ),
      ),
    );
  }

  Widget _contentBody(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF3D3D3D),
        height: 1.5,
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F56A0),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF7E8594), fontSize: 13),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F56A0),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    return null;
  }

  String? _validateRuc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    final clean = value.trim();
    if (!RegExp(r'^\d{11}$').hasMatch(clean)) {
      return 'RUC invalido (11 digitos)';
    }
    return null;
  }

  String? _validateEmailRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Correo invalido';
    }
    return null;
  }

  String? _orNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Widget _roleCard({
    required String role,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EEF8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1F56A0) : const Color(0xFFE4E7EF),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1F56A0).withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 28,
              color: isSelected ? const Color(0xFF1F56A0) : const Color(0xFF7E8594),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF1F56A0) : const Color(0xFF3D3D3D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
