import 'package:flutter/material.dart';

class EntityCard extends StatelessWidget {
  const EntityCard({
    super.key,
    this.leadingStripeColor,
    this.badge,
    this.title,
    this.subtitle,
    this.trailing,
    this.body,
    this.actions,
    this.onTap,
  });

  final Color? leadingStripeColor;
  final Widget? badge;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? body;
  final Widget? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4E7EE)),
          ),
          child: Stack(
            children: <Widget>[
              if (leadingStripeColor != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: leadingStripeColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (badge != null || trailing != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: badge ?? const SizedBox.shrink(),
                          ),
                          if (trailing != null) ...<Widget>[
                            const SizedBox(width: 8),
                            trailing!,
                          ],
                        ],
                      ),
                    if (title != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        title!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF252E3E),
                        ),
                      ),
                    ],
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF7E879A)),
                      ),
                    ],
                    if (body != null) ...<Widget>[
                      const SizedBox(height: 10),
                      body!,
                    ],
                    if (actions != null) ...<Widget>[
                      const SizedBox(height: 10),
                      actions!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
