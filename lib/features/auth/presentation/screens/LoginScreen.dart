import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mecanaut_mobile/core/di/AppProviders.dart';
import 'package:mecanaut_mobile/core/widgets/PrimaryButton.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authSession = ref.watch(authSessionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox(
                      height: 32,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
                const Center(
                  child: Text(
                    'Iniciar Sesion',
                    style: TextStyle(
                      color: Color(0xFF1F56A0),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Nos alegra tenerte de vuelta',
                    style: TextStyle(color: Color(0xFF74A5E8), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Usuario',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F56A0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu usuario',
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa tu usuario';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Contrasena',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F56A0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '*******',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contrasena';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: null,
                          child: const Text('Olvide mi contrasena'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        children: <Widget>[
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'o',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: null,
                              child: const Text('Google'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: null,
                              child: const Text('Microsoft'),
                            ),
                          ),
                        ],
                      ),
                      if (authSession.errorMessage != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          authSession.errorMessage!,
                          style: const TextStyle(color: Color(0xFFD7465E)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Iniciar Sesion',
                        isLoading: authSession.isLoading,
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) {
                            return;
                          }
                          final ok = await ref
                              .read(authSessionProvider)
                              .signIn(
                                username: _usernameController.text.trim(),
                                password: _passwordController.text,
                              );
                          if (ok && mounted) {
                            context.go('/');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                Center(
                  child: Wrap(
                    children: <Widget>[
                      const Text('No tienes una cuenta? '),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: const Text(
                          'Crea una',
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
    );
  }
}
