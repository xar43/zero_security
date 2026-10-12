import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/app_log.dart';

class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.color,
    this.isFile = false,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit fit;
  final double borderRadius;
  final Color? color;
  final bool isFile;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return _buildErrorWidget();

    if (isFile) {
      return Image.file(
        File(imageUrl!),
        height: height,
        width: width,
        fit: fit,
        color: color,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }

    return switch (imageUrl!) {
      final String url when url.startsWith('http') && url.endsWith('.svg') => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SvgPicture.network(
          url,
          height: height,
          width: width,
          fit: fit,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
          placeholderBuilder: (_) => _buildLoadingWidget(),
        ),
      ),
      final String url when url.startsWith('http') || url.endsWith('.webp') => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: width,
          fit: fit,
          color: color,
          errorWidget: (_, _, _) => _buildErrorWidget(),
          placeholder: (_, _) => _buildLoadingWidget(),
        ),
      ),
      final String url when url.startsWith('http') => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: width,
          fit: fit,
          color: color,
          errorWidget: (_, _, _) => _buildErrorWidget(),
          placeholder: (_, _) => _buildLoadingWidget(),
        ),
      ),
      final String url when url.endsWith('.svg') => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SvgPicture.asset(
          url,
          height: height,
          width: width,
          fit: fit,
          colorFilter: color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
        ),
      ),
      final String url when url.endsWith('.png') => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          imageUrl!,
          height: height,
          width: width,
          fit: fit,
          color: color,
          errorBuilder: (_, error, _) {
            AppLog.errorLog("CustomImageWidget", error);
            return _buildErrorWidget();
          },
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
        ),
      ),
      _ => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          imageUrl!,
          height: height,
          width: width,
          fit: fit,
          color: color,
          errorBuilder: (_, error, _) {
            AppLog.errorLog("CustomImageWidget", error);
            return _buildErrorWidget();
          },
        ),
      ),
    };
  }

  Widget _buildErrorWidget() => Container(
    height: height,
    width: width,
    color: Colors.grey[200],
    child: const Icon(Icons.broken_image, color: Colors.grey),
  );

  Widget _buildLoadingWidget() => CircularProgressIndicator.adaptive(
    backgroundColor: Colors.grey.withValues(alpha: 0.4),
    valueColor: const AlwaysStoppedAnimation(Colors.grey),
    strokeWidth: 2.5,
  );
}
