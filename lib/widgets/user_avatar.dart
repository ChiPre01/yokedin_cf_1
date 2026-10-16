
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yoked_in/services/cloudflare_media_service.dart';

class UserAvatar extends StatefulWidget {
  final String? photoUrl;
  final double radius;
  final IconData fallbackIcon;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.photoUrl,
    this.radius = 20,
    this.fallbackIcon = Icons.person,
    this.backgroundColor,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Future<Uint8List>? _cloudflareImageFuture;

  bool get _isCloudflareMedia {
    final value = widget.photoUrl;
    if (value == null || value.trim().isEmpty) return false;

    final uri = Uri.tryParse(value);
    final baseUri = Uri.tryParse(CloudflareMediaService.baseUrl);

    return uri != null &&
        baseUri != null &&
        uri.scheme == 'https' &&
        uri.host == baseUri.host &&
        uri.path.startsWith('/media/');
  }

  @override
  void initState() {
    super.initState();
    _loadCloudflareImage();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.photoUrl != widget.photoUrl) {
      _loadCloudflareImage();
    }
  }

  void _loadCloudflareImage() {
    if (_isCloudflareMedia) {
      _cloudflareImageFuture = CloudflareMediaService.instance
          .downloadMedia(widget.photoUrl!.trim());
    } else {
      _cloudflareImageFuture = null;
    }
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      child: Icon(
        widget.fallbackIcon,
        size: widget.radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = widget.photoUrl?.trim() ?? '';

    if (photoUrl.isEmpty) {
      return _fallback();
    }

    if (_isCloudflareMedia) {
      return FutureBuilder<Uint8List>(
        future: _cloudflareImageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: widget.radius,
              backgroundColor: widget.backgroundColor,
              child: SizedBox(
                width: widget.radius,
                height: widget.radius,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _fallback();
          }

          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: widget.backgroundColor,
            backgroundImage: MemoryImage(snapshot.data!),
          );
        },
      );
    }

    // Supports existing profile pictures hosted elsewhere,
    // including older Firebase Storage download URLs.
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor,
      backgroundImage: NetworkImage(photoUrl),
      onBackgroundImageError: (_, __) {},
      child: null,
    );
  }
}
