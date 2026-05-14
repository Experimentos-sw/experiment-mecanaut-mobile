import 'package:flutter/material.dart';
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
                    subtitle: 'Completa tus datos de administrador',
                    children: <Widget>[
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
                      const Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'He leido y acepto los ',
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Terminos y Condiciones',
                                style: TextStyle(color: Color(0xFF5B62B3)),
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
    );

    final ok = await ref.read(authSessionProvider).signUp(request);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada correctamente.')),
      );
      context.go('/login');
    }
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
}
