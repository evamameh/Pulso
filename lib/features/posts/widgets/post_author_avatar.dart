import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pulso/features/posts/domain/post.dart';

/// Circular author avatar for feed / post detail headers.
class PostAuthorAvatar extends StatelessWidget {
  const PostAuthorAvatar({super.key, required this.post, this.size = 38});

  final Post post;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = post.displayInitial;
    final url = post.authorAvatarUrl?.trim();
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

    return Container(
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
  }
}
