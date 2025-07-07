import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ErrorHandlingImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double opacity;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final bool isAvatar;

  const ErrorHandlingImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.opacity = 1.0,
    this.placeholder,
    this.borderRadius,
    this.isAvatar = false,
  });

  @override
  Widget build(BuildContext context) {
    // Default placeholder widget
    final defaultPlaceholder = Center(
      child: Icon(
        isAvatar ? Icons.person : Icons.image,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        size: isAvatar ? 24 : 48,
      ),
    );

    // Default error widget
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: borderRadius ?? BorderRadius.circular(isAvatar ? 50 : 0),
      ),
      child: defaultPlaceholder,
    );

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) {
        debugPrint('Error loading image from $url: $error');
        return defaultErrorWidget;
      },
    );

    // Apply opacity if needed
    if (opacity < 1.0) {
      image = Opacity(
        opacity: opacity,
        child: image,
      );
    }

    // Apply border radius if needed
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }
} 