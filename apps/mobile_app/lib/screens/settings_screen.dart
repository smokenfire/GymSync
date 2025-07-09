import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/animated_button.dart';
import '../core/services/location_service.dart';
import '../core/services/discord_service.dart';
import '../core/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const MethodChannel _channel = MethodChannel('change_app_icon');
  bool _discordLoggedIn = false;
  String? _discordUsername;
  bool _persistentNotification = NotificationService().enabled;

  @override
  void initState() {
    super.initState();
    _loadDiscordStatus();
  }

  Future<void> _loadDiscordStatus() async {
    final loggedIn = await DiscordService.isLoggedIn();
    final username = await DiscordService.getDiscordUsername();
    setState(() {
      _discordLoggedIn = loggedIn;
      _discordUsername = username;
    });
  }

  Future<void> _changeAppIcon(BuildContext context, String iconName) async {
    try {
      await _channel.invokeMethod('changeIcon', {'iconName': iconName});
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change icon: ${e.message}')),
      );
    }
  }

  Future<void> _handleDiscordButton() async {
    if (_discordLoggedIn) {
      await DiscordService.logout(context);
      setState(() {
        _discordLoggedIn = false;
        _discordUsername = null;
      });
    } else {
      final user = await DiscordService.connect(context);
      if (user != null) {
        setState(() {
          _discordLoggedIn = true;
          _discordUsername = user.username;
        });
      }
    }
  }

  Future<void> _handleReconfigureGymLocation(BuildContext context) async {
    final location = await LocationService.pickGymLocation(context);
    if (location != null && mounted) {
      // Reinicia o app para forçar reprocessamento da localização
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discordButtonText = _discordLoggedIn
        ? 'Logout'
        : 'Login Discord';

    final discordTileTitle = _discordLoggedIn && _discordUsername != null
        ? 'Connected as $_discordUsername'
        : 'Connect your Discord account';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            leading: const Icon(Icons.place),
            title: const Text('Reconfigure gym location'),
            trailing: AnimatedButton(
              text: 'Change',
              onPressed: () => _handleReconfigureGymLocation(context),
              small: true,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Choose app icon'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Image.asset('assets/infinity_blue.png', width: 32),
                  onPressed: () => _changeAppIcon(context, 'iconBlue'),
                ),
                IconButton(
                  icon: Image.asset('assets/infinity_red.png', width: 32),
                  onPressed: () => _changeAppIcon(context, 'iconRed'),
                ),
                IconButton(
                  icon: Image.asset('assets/infinity_green.png', width: 32),
                  onPressed: () => _changeAppIcon(context, 'iconGreen'),
                ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark theme'),
            value: false,
            onChanged: (v) {/*toggle theme*/},
          ),
          SwitchListTile(
            title: const Text('Widget Home ON/OFF'),
            value: true,
            onChanged: (v) {/*...*/},
          ),
          SwitchListTile(
            title: const Text('Persistent Notification ON/OFF'),
            value: _persistentNotification,
            onChanged: (v) {
              setState(() {
                _persistentNotification = v;
                NotificationService().enable(v);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(discordTileTitle),
            trailing: AnimatedButton(
              text: discordButtonText,
              onPressed: _handleDiscordButton,
              small: true,
            ),
          ),
        ],
      ),
    );
  }
}