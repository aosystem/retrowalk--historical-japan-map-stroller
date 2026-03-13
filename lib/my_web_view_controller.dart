import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class MyWebViewController {
  MyWebViewController() {
  }

  WebViewController controller({
    Future<bool> Function()? onRequestGeolocationPermission,
  }) {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
          },
        ),
      );
    controller.setBackgroundColor(const Color(0x00000000));
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setGeolocationEnabled(true);
      if (onRequestGeolocationPermission != null) {
          androidController.setGeolocationPermissionsPromptCallbacks(
            onShowPrompt: (params) async {
              final bool allow = await onRequestGeolocationPermission();
              return GeolocationPermissionsResponse(
                allow: allow,
                retain: true,
              );
            },
          );
        }
      }
    return controller;
  }
}
