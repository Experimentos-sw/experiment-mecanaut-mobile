import 'package:flutter/material.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.onClose,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E2E7),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE595AA),
                            letterSpacing: 0.4,
                            fontSize: 26 / 2,
                          ),
                        ),
                      ),
                      if (onClose != null)
                        IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
