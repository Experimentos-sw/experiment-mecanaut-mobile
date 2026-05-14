import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/features/personnel/data/models/create_user_request.dart';

class NewPersonnelResult {
  NewPersonnelResult({
    required this.request,
    this.localDni,
    this.localPhone,
    this.localNotes,
  });

  final CreateUserRequest request;
  final String? localDni;
  final String? localPhone;
  final String? localNotes;
}

class NewPersonnelModal extends StatefulWidget {
  const NewPersonnelModal({
    super.key,
    required this.isSubmitting,
    required this.availableRoles,
  });

  final bool isSubmitting;
  final List<String> availableRoles;

  @override
  State<NewPersonnelModal> createState() => _NewPersonnelModalState();
}

class _NewPersonnelModalState extends State<NewPersonnelModal> {
  final _formKey = GlobalKey<FormState>();
  final _namesController = TextEditingController();
  final _lastNamesController = TextEditingController();
  final _dniController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _annotationsController = TextEditingController();
  String _selectedRole = 'RoleTechnical';

  @override
  void initState() {
    super.initState();
    if (widget.availableRoles.isNotEmpty) {
      _selectedRole = widget.availableRoles.contains('RoleTechnical')
          ? 'RoleTechnical'
          : widget.availableRoles.first;
    }
  }

  @override
  void dispose() {
    _namesController.dispose();
    _lastNamesController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _annotationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE4E4E6))),
              ),
              child: const Text(
                'Nuevo Personal',
                style: TextStyle(
                  color: Color(0xFF1F56A0),
                  fontWeight: FontWeight.w700,
                  fontSize: 34 / 2,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _label('Nombre(s)'),
                      _input(_namesController, hint: 'Ej. Juan'),
                      _gap(),
                      _label('Apellidos'),
                      _input(_lastNamesController, hint: 'Ej. Perez Diaz'),
                      _gap(),
                      _label('DNI'),
                      _input(
                        _dniController,
                        hint: '12345678',
                        keyboardType: TextInputType.number,
                        required: false,
                      ),
                      _gap(),
                      _label('Numero telefonico'),
                      _input(
                        _phoneController,
                        hint: '987654321',
                        keyboardType: TextInputType.phone,
                        required: false,
                      ),
                      _gap(),
                      _label('Correo'),
                      _input(
                        _emailController,
                        hint: 'perez.j@company.com',
                        keyboardType: TextInputType.emailAddress,
                        email: true,
                      ),
                      _gap(),
                      _label('Cargo'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        items:
                            (widget.availableRoles.isEmpty
                                    ? const <String>[
                                        'RoleTechnical',
                                        'RoleAdmin',
                                      ]
                                    : widget.availableRoles)
                                .map(
                                  (e) => DropdownMenuItem<String>(
                                    value: e,
                                    child: Text(_roleLabel(e)),
                                  ),
                                )
                                .toList(),
                        decoration: const InputDecoration(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() => _selectedRole = value);
                          }
                        },
                      ),
                      _gap(),
                      _label('Anotaciones'),
                      TextFormField(
                        controller: _annotationsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Anadir nota...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE4E4E6))),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE24B6C),
                        side: const BorderSide(color: Color(0xFFE24B6C)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.isSubmitting ? null : _submit,
                      child: widget.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller, {
    required String hint,
    bool required = true,
    bool email = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(hintText: hint),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return 'Campo requerido';
        }
        if (email &&
            value != null &&
            value.isNotEmpty &&
            !value.contains('@')) {
          return 'Correo invalido';
        }
        return null;
      },
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF3A3A3A),
      ),
    ),
  );

  Widget _gap() => const SizedBox(height: 14);

  String _roleLabel(String role) {
    switch (role) {
      case 'RoleAdmin':
        return 'Administrador';
      case 'RoleTechnical':
        return 'Tecnico';
      default:
        return role;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final email = _emailController.text.trim();
    final username = email.split('@').first;
    final request = CreateUserRequest(
      username: username,
      password: 'Temp#${DateTime.now().millisecondsSinceEpoch % 999999}',
      email: email,
      firstName: _namesController.text.trim(),
      lastName: _lastNamesController.text.trim(),
      roles: <String>[_selectedRole],
    );

    Navigator.of(context).pop(
      NewPersonnelResult(
        request: request,
        localDni: _dniController.text.trim(),
        localPhone: _phoneController.text.trim(),
        localNotes: _annotationsController.text.trim(),
      ),
    );
  }
}
