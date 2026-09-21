import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';

class AvatarImageHelper {
  /// Resolves an avatar string (data URI, base64, relative path, or full URL) into an ImageProvider
  static ImageProvider? getImageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = avatarUrl.trim();

    // 1. Data URI (e.g. data:image/png;base64,... or data:application/octet-stream;base64,...)
    if (trimmed.startsWith('data:') || trimmed.contains(';base64,')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = trimmed.substring(commaIndex + 1).replaceAll(RegExp(r'\s+'), '');
          final bytes = base64Decode(base64Str);
          return MemoryImage(bytes);
        }
      } catch (_) {}
    }

    // 2. Raw Base64 string without data: header (starts with PNG/JPEG base64 headers)
    if ((trimmed.startsWith('iVBORw0KGgo') || trimmed.startsWith('/9j/') || trimmed.startsWith('UklGR')) &&
        trimmed.length > 50) {
      try {
        final cleanBase64 = trimmed.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(cleanBase64);
        return MemoryImage(bytes);
      } catch (_) {}
    }

    // 3. Absolute HTTP/HTTPS external URL (e.g. Unsplash or external CDN)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    // 4. Uploaded avatar / relative file paths (e.g. avatar_... or /uploads/... or logo.png)
    final cleanBaseUrl = ApiService.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final baseHost = cleanBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

    if (trimmed.startsWith('/')) {
      return NetworkImage('$baseHost$trimmed');
    } else {
      return NetworkImage('$baseHost/$trimmed');
    }
  }

  /// Builds an avatar widget with graceful fallback to initials
  static Widget buildAvatar({
    required String? avatarUrl,
    required String name,
    double radius = 24,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final image = getImageProvider(avatarUrl);
    final initials = name.trim().isNotEmpty
        ? name.trim().split(RegExp(r'\s+')).take(2).map((s) => s.isNotEmpty ? s[0].toUpperCase() : '').join()
        : 'ST';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xFFEFF6FF),
      backgroundImage: image,
      onBackgroundImageError: image != null ? (exception, stackTrace) {} : null,
      child: image == null
          ? Text(
              initials,
              style: TextStyle(
                color: textColor ?? const Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.7,
              ),
            )
          : null,
    );
  }
}
