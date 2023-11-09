import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart';

class OurImageProvider extends ImageProvider<_OurKey> {
  final ImageProvider? imageProvider;
  OurImageProvider({
    this.imageProvider,
  });

  @override
  ImageStreamCompleter load(_OurKey key, DecoderCallback decode) {
    // ignore: prefer_function_declarations_over_variables
    var ourDecorder;
    ourDecorder = (
      Uint8List bytes, {
      bool? allowUpScaling,
      int? cacheWidth,
      int? cacheheight,
    }) async {
      return decode(await whiteToAlpha(bytes),
          cacheWidth: cacheWidth, cacheHeight: cacheheight);
    };
    return imageProvider!.loadImage(key.providerCacheKey!, ourDecorder);
  }

  @override
  Future<_OurKey> obtainKey(ImageConfiguration configuration) {
    Completer<_OurKey>? completer;

    SynchronousFuture<_OurKey>? result;
    imageProvider!.obtainKey(configuration).then((Object key) {
      if (completer == null) {
        result = SynchronousFuture<_OurKey>(_OurKey(providerCacheKey: key));
      } else {
        completer.complete(_OurKey(providerCacheKey: key));
      }
    });
    if (result != null) {
      return result!;
    }

    completer = Completer<_OurKey>();
    return completer.future;
  }

  Future<Uint8List> whiteToAlpha(Uint8List bytes) async {
    final image = decodeImage(bytes);

    final pixels = image!.getBytes(format: Format.rgba);
    final length = pixels.lengthInBytes;
    for (var i = 0; i < length; i += 4) {
      if (pixels[i] == 255 && pixels[i + 1] == 255 && pixels[i + 2] == 255) {
        pixels[i + 3] = 0;
      }
    }
    return encodePng(image) as Uint8List;
  }
}

class _OurKey {
  final Object? providerCacheKey;
  _OurKey({
    this.providerCacheKey,
  });

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is _OurKey && other.providerCacheKey == providerCacheKey;
  }

  @override
  int get hashCode => providerCacheKey.hashCode;
}
