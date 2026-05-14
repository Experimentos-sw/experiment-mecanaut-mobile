import 'package:flutter/material.dart';

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final normalizedMessage = _normalizeMessage(message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(normalizedMessage, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _normalizeMessage(String input) {
    final lower = input.toLowerCase();
    if (lower.contains(
      'object reference not set to an instance of an object',
    )) {
      return 'No se pudo cargar la informacion. La sesion no esta lista o el servidor devolvio un error.';
    }
    return input;
  }
}
