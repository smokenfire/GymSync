import os

# Map file paths to their contents (all in English)
files = {
    "lib/main.dart": '''
import 'package:flutter/material.dart';
import 'app.dart';

void main() => runApp(const MyApp());
''',

    "lib/app.dart": '''
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Discord App',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
''',

    "lib/core/theme.dart": '''
import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
  );
}
''',

    "lib/core/assets.dart": '''
class Assets {
  static const infinityBlue = 'assets/images/infinity_blue.svg';
  static const infinityRed = 'assets/images/infinity_red.svg';
  static const infinityGreen = 'assets/images/infinity_green.svg';
}
''',

    "lib/core/icons.dart": '''
class AppIcons {
  static const footprints = 'assets/images/footprints.svg';
  static const bike = 'assets/images/bike.svg';
  static const dumbbell = 'assets/images/dumbbell.svg';
}
''',

    "lib/core/services/auth_service.dart": '''
class AuthService {
  // Implement authentication logic here
}
''',

    "lib/core/services/backend_service.dart": '''
class BackendService {
  static void pause() {}
  static void resume() {}
  static void stop() {}
}
''',

    "lib/core/services/discord_service.dart": '''
import 'package:flutter/material.dart';

class DiscordService {
  static Future<User?> connect(BuildContext context) async {
    // Implement OAuth2 Discord connection
    return User(username: 'ExampleUser', id: '123456');
  }

  static void logout(BuildContext context) {}
}

class User {
  final String username;
  final String id;
  User({required this.username, required this.id});
}
''',

    "lib/core/services/google_fit_service.dart": '''
class GoogleFitService {
  static Future<bool> requestPermission() async {
    // Implement Google Fit/Health access
    return true;
  }
}
''',

    "lib/core/services/location_service.dart": '''
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static Future<LatLng?> pickGymLocation(BuildContext context) async {
    LatLng? selected;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MapPickerScreen(onSelected: (latlng) => selected = latlng),
    ));
    return selected;
  }
}

class _MapPickerScreen extends StatefulWidget {
  final Function(LatLng) onSelected;
  const _MapPickerScreen({required this.onSelected});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  LatLng? picked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select your gym location')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(37.7749, -122.4194), // Example: San Francisco
          zoom: 15,
        ),
        onTap: (latlng) => setState(() => picked = latlng),
        markers: picked == null
            ? {}
            : {
                Marker(markerId: const MarkerId('gym'), position: picked!),
              },
      ),
      floatingActionButton: picked != null
          ? FloatingActionButton.extended(
              label: const Text('Confirm'),
              icon: const Icon(Icons.check),
              onPressed: () {
                widget.onSelected(picked!);
                Navigator.of(context).pop();
              },
            )
          : null,
    );
  }
}
''',

    "lib/core/services/notification_service.dart": '''
class NotificationService {
  // Implement persistent notification logic here
}
''',

    "lib/core/services/widget_service.dart": '''
class WidgetService {
  // Implement homescreen widget logic here
}
''',

    "lib/core/models/user.dart": '''
class User {
  final String username;
  final String id;
  User({required this.username, required this.id});
}
''',

    "lib/core/models/session.dart": '''
class Session {
  final String activityType;
  final Duration duration;
  Session({required this.activityType, required this.duration});
}
''',

    "lib/screens/splash_screen.dart": '''
import 'package:flutter/material.dart';
import '../widgets/animated_infinity.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedInfinity(
          color: Colors.blue,
          size: 120,
        ),
      ),
    );
  }
}
''',

    "lib/screens/onboarding_screen.dart": '''
import 'package:flutter/material.dart';
import '../widgets/animated_button.dart';
import '../core/services/discord_service.dart';
import '../core/services/location_service.dart';
import '../core/services/google_fit_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool discordConnected = false;
  bool locationSet = false;
  bool healthGranted = false;
  String? discordUsername;

  void connectDiscord() async {
    final user = await DiscordService.connect(context);
    if (user != null) {
      setState(() {
        discordConnected = true;
        discordUsername = user.username;
      });
    }
  }

  void selectGym() async {
    final location = await LocationService.pickGymLocation(context);
    if (location != null) {
      setState(() => locationSet = true);
    }
  }

  void enableHealth() async {
    final granted = await GoogleFitService.requestPermission();
    setState(() => healthGranted = granted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              _StepTile(
                title: 'Connect your Discord account.',
                status: discordConnected,
                onPressed: connectDiscord,
                buttonText: 'Connect Discord',
              ),
              const SizedBox(height: 16),
              _StepTile(
                title: 'Select your gym location.',
                status: locationSet,
                onPressed: selectGym,
                buttonText: 'Select Gym Location',
              ),
              const SizedBox(height: 16),
              _StepTile(
                title: 'Allow access to Google Fit.',
                status: healthGranted,
                onPressed: enableHealth,
                buttonText: 'Enable Health Data',
              ),
              const Spacer(),
              AnimatedButton(
                enabled: discordConnected && locationSet && healthGranted,
                text: 'Start',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final bool status;
  final VoidCallback onPressed;
  final String buttonText;

  const _StepTile({
    required this.title,
    required this.status,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: status
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.radio_button_unchecked),
      title: Text(title),
      trailing: AnimatedButton(
        enabled: !status,
        text: buttonText,
        onPressed: onPressed,
        small: true,
      ),
    );
  }
}
''',

    "lib/screens/home_screen.dart": '''
import 'package:flutter/material.dart';
import '../widgets/circular_timer.dart';
import '../widgets/activity_icon.dart';
import '../widgets/discord_status_indicator.dart';
import '../widgets/animated_button.dart';
import '../core/services/backend_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool running = false;
  Duration elapsed = Duration.zero;
  String activity = 'footprints';
  String lastSession = '00:00 - footprints';

  void onPause() {
    BackendService.pause();
    setState(() => running = false);
  }

  void onResume() {
    BackendService.resume();
    setState(() => running = true);
  }

  void onStop() {
    BackendService.stop();
    setState(() {
      running = false;
      lastSession = '12:34 - $activity';
      elapsed = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          )
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularTimer(
              running: running,
              duration: elapsed,
              activity: activity,
            ),
            const SizedBox(height: 24),
            ActivityIcon(activity: activity, size: 48),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (running)
                  AnimatedButton(text: 'Pause', onPressed: onPause)
                else
                  AnimatedButton(text: 'Resume', onPressed: onResume),
                const SizedBox(width: 16),
                AnimatedButton(text: 'Stop', onPressed: onStop),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Last session: $lastSession',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const DiscordStatusIndicator(),
          ],
        ),
      ),
    );
  }
}
''',

    "lib/screens/settings_screen.dart": '''
import 'package:flutter/material.dart';
import '../widgets/animated_button.dart';
import '../core/services/location_service.dart';
import '../core/services/discord_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => LocationService.pickGymLocation(context),
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
                  icon: Image.asset('assets/images/infinity_blue.png', width: 32),
                  onPressed: () {/*change icon*/},
                ),
                IconButton(
                  icon: Image.asset('assets/images/infinity_red.png', width: 32),
                  onPressed: () {/*change icon*/},
                ),
                IconButton(
                  icon: Image.asset('assets/images/infinity_green.png', width: 32),
                  onPressed: () {/*change icon*/},
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
            value: true,
            onChanged: (v) {/*...*/},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout Discord'),
            trailing: AnimatedButton(
              text: 'Logout',
              onPressed: () => DiscordService.logout(context),
              small: true,
            ),
          ),
        ],
      ),
    );
  }
}
''',

    "lib/screens/connected_screen.dart": '''
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../widgets/animated_button.dart';
import 'home_screen.dart';

class ConnectedScreen extends StatelessWidget {
  final String username;
  final String userId;

  const ConnectedScreen({super.key, required this.username, required this.userId});

  @override
  Widget build(BuildContext context) {
    final confettiController = ConfettiController(duration: const Duration(seconds: 2));
    WidgetsBinding.instance.addPostFrameCallback((_) => confettiController.play());

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Connected to Discord!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Username: $username'),
                Text('ID: $userId'),
                const SizedBox(height: 16),
                AnimatedButton(
                  text: 'Go to Home',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
''',

    "lib/widgets/animated_infinity.dart": '''
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/assets.dart';

class AnimatedInfinity extends StatefulWidget {
  final Color color;
  final double size;
  const AnimatedInfinity({super.key, required this.color, required this.size});

  @override
  State<AnimatedInfinity> createState() => _AnimatedInfinityState();
}

class _AnimatedInfinityState extends State<AnimatedInfinity>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        Assets.infinityBlue,
        color: widget.color,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
''',

    "lib/widgets/animated_button.dart": '''
import 'package:flutter/material.dart';

class AnimatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final bool small;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            EdgeInsets.symmetric(horizontal: small ? 16 : 32, vertical: small ? 8 : 16),
        decoration: BoxDecoration(
          color: enabled ? Colors.blue : Colors.grey,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: small ? 14 : 18),
        ),
      ),
    );
  }
}
''',

    "lib/widgets/circular_timer.dart": '''
import 'package:flutter/material.dart';

class CircularTimer extends StatelessWidget {
  final bool running;
  final Duration duration;
  final String activity;

  const CircularTimer({
    super.key,
    required this.running,
    required this.duration,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (duration.inSeconds % 60) / 60.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),
        ),
        Text(
          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
''',

    "lib/widgets/activity_icon.dart": '''
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/icons.dart';

class ActivityIcon extends StatelessWidget {
  final String activity;
  final double size;

  const ActivityIcon({super.key, required this.activity, this.size = 32});

  @override
  Widget build(BuildContext context) {
    String asset;
    switch (activity) {
      case 'bike':
        asset = AppIcons.bike;
        break;
      case 'dumbbell':
        asset = AppIcons.dumbbell;
        break;
      default:
        asset = AppIcons.footprints;
    }
    return SvgPicture.asset(asset, width: size, height: size);
  }
}
''',

    "lib/widgets/discord_status_indicator.dart": '''
import 'package:flutter/material.dart';

class DiscordStatusIndicator extends StatelessWidget {
  const DiscordStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final bool rpcActive = true;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.discord, color: rpcActive ? Colors.green : Colors.red),
        const SizedBox(width: 8),
        Text(rpcActive ? 'Discord RPC active' : 'Discord RPC inactive'),
      ],
    );
  }
}
''',
}

def ensure_dir_exists(path):
    if not os.path.exists(path):
        os.makedirs(path)

for filepath, content in files.items():
    dirpath = os.path.dirname(filepath)
    ensure_dir_exists(dirpath)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content.lstrip())

print("Flutter project structure generated in /lib.")