import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/features/assets/data/services/PlantsService.dart';

class NewPlantModal extends StatefulWidget {
  const NewPlantModal({super.key});

  @override
  State<NewPlantModal> createState() => _NewPlantModalState();
}

class _NewPlantModalState extends State<NewPlantModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController(text: 'Peru');
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: <Widget>[
                  const Text(
                    'Nueva Planta',
                    style: TextStyle(
                      color: Color(0xFF1F56A0),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _label('Nombre'),
                    _input(
                      controller: _nameController,
                      hintText: 'Planta Principal',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _label('Direccion'),
                    _input(
                      controller: _addressController,
                      hintText: 'Av. Industrial 123',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _label('Ciudad'),
                    _input(
                      controller: _cityController,
                      hintText: 'Lima',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _label('Pais'),
                    _input(
                      controller: _countryController,
                      hintText: 'Peru',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _label('Telefono'),
                    _input(
                      controller: _phoneController,
                      hintText: '+51 999 888 777',
                      keyboardType: TextInputType.phone,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _label('Correo'),
                    _input(
                      controller: _emailController,
                      hintText: 'planta@empresa.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE24B6C),
                              side: const BorderSide(color: Color(0xFFE24B6C)),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, color: Color(0xFF353535)),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(hintText: hintText),
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Correo invalido';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CreatePlantRequest(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      ),
    );
  }
}
