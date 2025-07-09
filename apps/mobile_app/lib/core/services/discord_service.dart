import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class DiscordService {
  static const String clientId = '1391871101734223912';
  static const String redirectUri = ''; // your redirect URI here
  static const String scope = 'identify';

  static Future<User?> connect(BuildContext context) async {
    final oauthUrl =
        'https://discord.com/api/oauth2/authorize?client_id=$clientId&redirect_uri=${Uri.encodeComponent(redirectUri)}&response_type=token&scope=$scope';

    final result = await Navigator.of(context).push<User?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DiscordWebView(oauthUrl: oauthUrl, redirectUri: redirectUri),
      ),
    );
    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('discord_username', result.username);
      await prefs.setString('discord_id', result.id);
      await prefs.setString('onboarding_discord_id', result.id);
      await prefs.setBool('discord_logged_in', true);
    }
    return result;
  }

  static Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('discord_username');
    await prefs.remove('discord_id');
    await prefs.remove('onboarding_discord_id');
    await prefs.setBool('discord_logged_in', false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logout completed successfully.')),
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('discord_logged_in') ?? false;
  }

  static Future<String?> getDiscordUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('discord_username');
  }
}

class User {
  final String username;
  final String id;
  User({required this.username, required this.id});
}

class DiscordWebView extends StatefulWidget {
  final String oauthUrl;
  final String redirectUri;
  const DiscordWebView({required this.oauthUrl, required this.redirectUri, super.key});

  @override
  State<DiscordWebView> createState() => _DiscordWebViewState();
}

class _DiscordWebViewState extends State<DiscordWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
            _checkForRedirect(url);
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
            _checkForRedirect(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.oauthUrl));
  }

  void _checkForRedirect(String url) async {
    if (_handled) return;
    if (url.startsWith(widget.redirectUri)) {
      _handled = true;
      final uri = Uri.parse(url);
      final fragment = uri.fragment;
      if (fragment.isEmpty) {
        Navigator.of(context).pop(null);
        return;
      }
      final params = Uri.splitQueryString(fragment);
      final accessToken = params['access_token'];
      if (accessToken == null) {
        Navigator.of(context).pop(null);
        return;
      }
      try {
        final res = await http.get(
          Uri.parse('https://discord.com/api/users/@me'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          Navigator.of(context).pop(User(
            username: data['username'] ?? '',
            id: data['id'] ?? '',
          ));
        } else {
          Navigator.of(context).pop(null);
        }
      } catch (_) {
        Navigator.of(context).pop(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discord Login')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
