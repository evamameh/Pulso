import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulso/features/posts/domain/comment.dart';

/// Circular avatar for a comment author (uses [CachedNetworkImage] when URL set).
class CommentAuthorAvatar extends StatelessWidget {
  const CommentAuthorAvatar({
    super.key,
    required this.comment,
    this.size = 36,
    this.onTap,
  });

  final Comment comment;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = comment.displayInitial;
    final url = comment.avatarUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    final initialStyle = TextStyle(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
      fontSize: size * 0.42,
    );

    final fallback = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(child: Text(initial, style: initialStyle)),
    );

    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );

    if (onTap == null) return inner;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'View profile',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: inner,
        ),
      ),
    );
  }
}
