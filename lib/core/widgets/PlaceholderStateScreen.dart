import 'package:flutter/material.dart';
import 'package:mecanaut_mobile/core/widgets/ErrorStateView.dart';
import 'package:mecanaut_mobile/core/widgets/LoadingView.dart';

class PlaceholderStateScreen extends StatefulWidget {
  const PlaceholderStateScreen({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  State<PlaceholderStateScreen> createState() => _PlaceholderStateScreenState();
}

enum _ScreenState { success, loading, empty, error }

class _PlaceholderStateScreenState extends State<PlaceholderStateScreen> {
  _ScreenState _state = _ScreenState.success;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SegmentedButton<_ScreenState>(
          segments: const <ButtonSegment<_ScreenState>>[
            ButtonSegment<_ScreenState>(
              value: _ScreenState.success,
              label: Text('Success'),
            ),
            ButtonSegment<_ScreenState>(
              value: _ScreenState.loading,
              label: Text('Loading'),
            ),
            ButtonSegment<_ScreenState>(
              value: _ScreenState.empty,
              label: Text('Empty'),
            ),
            ButtonSegment<_ScreenState>(
              value: _ScreenState.error,
              label: Text('Error'),
            ),
          ],
          selected: <_ScreenState>{_state},
          onSelectionChanged: (Set<_ScreenState> selection) {
            setState(() => _state = selection.first);
          },
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildState()),
      ],
    );
  }

  Widget _buildState() {
    switch (_state) {
      case _ScreenState.loading:
        return const LoadingView(message: 'Cargando modulo...');
      case _ScreenState.empty:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              const Text('No hay informacion para mostrar aun.'),
            ],
          ),
        );
      case _ScreenState.error:
        return ErrorStateView(
          message: 'No se pudo cargar la vista. Intenta nuevamente.',
          onRetry: () => setState(() => _state = _ScreenState.success),
        );
      case _ScreenState.success:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(widget.description),
                const SizedBox(height: 8),
                const Text(
                  'Vista placeholder lista para integrar logica de negocio en la siguiente fase.',
                ),
              ],
            ),
          ),
        );
    }
  }
}
