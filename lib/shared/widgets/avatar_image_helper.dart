import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';

class AvatarImageHelper {
  /// Resolves an avatar string (data URI, relative path, or full URL) into an ImageProvider
  static ImageProvider? getImageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return null;
    }

    final trimmed = avatarUrl.trim();

    // 1. Base64 Data URI (e.g. data:image/png;base64,...)
    if (trimmed.startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        if (commaIndex != -1) {
          final base64Str = trimmed.substring(commaIndex + 1);
          final bytes = base64Decode(base64Str);
          return MemoryImage(bytes);
        }
      } catch (_) {}
    }

    // 2. Uploaded student avatar images (e.g. avatar_... or /uploads/avatars/...)
    // Always routes through /api/upload/{filename} with CORS headers (Access-Control-Allow-Origin: *) to fix Flutter Web canvas issues
    if (trimmed.contains('avatar_')) {
      final match = RegExp(r'avatar_[a-zA-Z0-9_\-\.]+').firstMatch(trimmed);
      if (match != null) {
        final filename = match.group(0)!;
        final cleanBaseUrl = ApiService.baseUrl.replaceAll(RegExp(r'/+$'), '');
        final corsUrl = cleanBaseUrl.endsWith('/api')
            ? '$cleanBaseUrl/upload/$filename'
            : '$cleanBaseUrl/api/upload/$filename';
        return NetworkImage(corsUrl);
      }
    }

    if (trimmed.contains('/uploads/')) {
      final uploadSubpath = trimmed.substring(trimmed.indexOf('/uploads/'));
      final filename = uploadSubpath.split('/').last;
      if (filename.isNotEmpty) {
        final cleanBaseUrl = ApiService.baseUrl.replaceAll(RegExp(r'/+$'), '');
        final corsUrl = cleanBaseUrl.endsWith('/api')
            ? '$cleanBaseUrl/upload/$filename'
            : '$cleanBaseUrl/api/upload/$filename';
        return NetworkImage(corsUrl);
      }
    }

    // 3. Absolute HTTP/HTTPS external URL (e.g. Unsplash or external CDN)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    // 4. Any other relative path
    if (trimmed.startsWith('/')) {
      final baseHost = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      return NetworkImage('$baseHost$trimmed');
    }

    return null;
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
