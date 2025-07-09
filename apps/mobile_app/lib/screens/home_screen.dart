import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import '../widgets/circular_timer.dart';
import '../widgets/activity_icon.dart';
import '../widgets/discord_status_indicator.dart';
import '../widgets/animated_button.dart';
import '../core/services/backend_service.dart';
import '../core/services/google_fit_service.dart';
import '../core/services/notification_service.dart';
import 'settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

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

  LatLng? gymLocation;
  static const double gymRadiusMeters = 35.0;
  bool inGym = false;
  bool locationChecked = false;
  Timer? _locationTimer;
  Timer? _statusTimer;
  bool _notifEnabled = true;

  @override
  void initState() {
    super.initState();
    NotificationService().init();
    NotificationService().onAction = _onNotificationAction;
    _startBackgroundMode();
    _loadGymLocation().then((_) {
      _checkIfInGym().then((_) {
        if (inGym) {
          _startGymFlowIfNeeded();
        } else {
          _checkAndStartActiveExercise();
        }
        _startLocationMonitoring();
      });
    });
  }

  Future<void> _startBackgroundMode() async {
    final hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      await FlutterBackground.initialize(
        androidConfig: const FlutterBackgroundAndroidConfig(
          notificationTitle: "GymSync Running",
          notificationText: "Your workout is being monitored in the background.",
          enableWifiLock: true,
        ),
      );
    }
    await FlutterBackground.enableBackgroundExecution();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _statusTimer?.cancel();
    NotificationService().cancel();
    FlutterBackground.disableBackgroundExecution();
    super.dispose();
  }

  void _onNotificationAction(String action) {
    if (action == 'pause') {
      onPause();
    } else if (action == 'stop') {
      onStop();
    }
  }

  void _maybeUpdateNotification() {
    if (!running || !NotificationService().enabled) {
      NotificationService().cancel();
      return;
    }
    NotificationService().show(
      elapsed: _formatElapsed(elapsed),
      activity: activity,
    );
  }

  void _startLocationMonitoring() {
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _checkIfInGym();
      if (inGym) {
        _startGymFlowIfNeeded();
      } else if (!inGym && running && activity == "Gym") {
        onStop();
        _checkAndStartActiveExercise();
      }
    });
  }

  void _startGymFlowIfNeeded() async {
    if (!running || activity != "Gym") {
      await BackendService.start("Gym");
      setState(() {
        activity = "Gym";
        running = true;
        elapsed = Duration.zero;
      });
      _startStatusUpdates();
      _maybeUpdateNotification();
    }
  }

  void _startStatusUpdates() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!running) return;
      setState(() {
        elapsed += const Duration(seconds: 1);
      });
      await BackendService.start(activity);
      _maybeUpdateNotification();
    });
  }

  void _stopStatusUpdates() {
    _statusTimer?.cancel();
  }

  Future<void> _loadGymLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('gym_lat');
    final lng = prefs.getDouble('gym_lng');
    if (lat != null && lng != null) {
      gymLocation = LatLng(lat, lng);
    }
    setState(() {
      locationChecked = true;
    });
  }

  Future<void> _checkIfInGym() async {
    if (gymLocation == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      final Distance distance = Distance();
      final double dist = distance(
        LatLng(pos.latitude, pos.longitude),
        gymLocation!,
      );
      setState(() {
        inGym = dist <= gymRadiusMeters;
      });
    } catch (_) {
      setState(() {
        inGym = false;
      });
    }
  }

  Future<void> _checkAndStartActiveExercise() async {
    if (inGym) return;
    final granted = await GoogleFitService.requestPermission();
    if (!granted) return;
    final exerciseType = await GoogleFitService().getCurrentActiveExerciseType();
    if (exerciseType != null && !running) {
      await BackendService.start(exerciseType);
      setState(() {
        activity = exerciseType;
        running = true;
        elapsed = Duration.zero;
      });
      _startStatusUpdates();
      _maybeUpdateNotification();
    }
  }

  void onPause() async {
    await BackendService.pause();
    setState(() => running = false);
    _stopStatusUpdates();
    NotificationService().cancel();
  }

  void onResume() async {
    await BackendService.resume();
    setState(() => running = true);
    _startStatusUpdates();
    _maybeUpdateNotification();
  }

  void onStop() async {
    await BackendService.stop();
    setState(() {
      running = false;
      lastSession = '${_formatElapsed(elapsed)} - $activity';
      elapsed = Duration.zero;
    });
    _stopStatusUpdates();
    NotificationService().cancel();
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  void _doNothing() {}

  @override
  Widget build(BuildContext context) {
    final bool controlsEnabled = running;

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
        child: locationChecked
            ? Column(
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
                      AnimatedButton(
                        text: running ? 'Pause' : 'Resume',
                        onPressed: controlsEnabled
                            ? (running ? onPause : onResume)
                            : _doNothing,
                        enabled: controlsEnabled,
                      ),
                      const SizedBox(width: 16),
                      AnimatedButton(
                        text: 'Stop',
                        onPressed: controlsEnabled ? onStop : _doNothing,
                        enabled: controlsEnabled,
                      ),
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
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}