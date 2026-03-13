import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:retrowalk/l10n/app_localizations.dart';
import 'package:retrowalk/setting_page.dart';
import 'package:retrowalk/ad_manager.dart';
import 'package:retrowalk/ad_banner_widget.dart';
import 'package:retrowalk/my_web_view_controller.dart';
import 'package:retrowalk/local_server.dart';
import 'package:retrowalk/loading_screen.dart';
import 'package:retrowalk/model.dart';
import 'package:retrowalk/theme_color.dart';
import 'package:retrowalk/main.dart';
import 'package:retrowalk/parse_locale_tag.dart';
import 'package:retrowalk/theme_mode_number.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late AdManager _adManager;
  final MyWebViewController _myWebViewController = MyWebViewController();
  final LocalServer _localServer = LocalServer();
  late final WebViewController _webViewController;
  //
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _webViewController = _myWebViewController.controller(
      onRequestGeolocationPermission: _requestLocationPermission,
    );
    await _localServer.start();
    await _requestLocationPermission();
    _updateWebView();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _adManager.dispose();
    _localServer.close();
    super.dispose();
  }

  void _updateWebView() async {
    String serverUrl = _localServer.url();
    await _webViewController.loadRequest(Uri.parse('${serverUrl}index.html'));
  }

  Future<void> _onOpenSetting() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingPage()),
    );
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..setState(() {});
      }
      _isFirst = true;
    }
    setState(() {});
  }

  Future<bool> _requestLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }
    final permission = Permission.locationWhenInUse;
    var status = await permission.status;
    if (status.isGranted) {
      return true;
    }
    status = await permission.request();
    if (status.isGranted) {
      return true;
    }
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.locationPermissionRequiredMessage),
        duration: const Duration(seconds: 10),
      ));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: LoadingScreen(),
      );
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _webViewController),
          ),
          Positioned(top: 0, left: 0, right: 0,
            child: AppBar(
              backgroundColor: _themeColor.mainBackColor.withValues(alpha: 0.2),
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  color: _themeColor.mainForeColor,
                  onPressed: _onOpenSetting,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0,
            child: AdBannerWidget(adManager: _adManager),
          ),
        ],
      ),
    );
  }

}
