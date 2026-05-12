import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ParkingApp());
}

class ParkingApp extends StatefulWidget {
  const ParkingApp({super.key});

  @override
  State<ParkingApp> createState() => _ParkingAppState();
}

class _ParkingAppState extends State<ParkingApp> {
  bool darkMode = false;

  void toggleTheme() {
    setState(() {
      darkMode = !darkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking My Car',
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,

      darkTheme: ThemeData.dark(),

      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),

      home: SplashScreen(
        toggleTheme: toggleTheme,
        darkMode: darkMode,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool darkMode;

  const SplashScreen({
    super.key,
    required this.toggleTheme,
    required this.darkMode,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(
      3.seconds,
      () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(
              toggleTheme: widget.toggleTheme,
              darkMode: widget.darkMode,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue,
              Colors.cyan,
            ],
          ),
        ),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            child: AnimatedTextKit(
              animatedTexts: [
                FadeAnimatedText('Parking My Car'),
              ],
              repeatForever: true,
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool darkMode;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.darkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LatLng? savedLocation;
  String parkingTime = "";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadSavedLocation();
  }

  Future<void> saveParkingLocation() async {
    setState(() {
      loading = true;
    });

    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble('lat', position.latitude);
    await prefs.setDouble('lng', position.longitude);

    String time =
        "${DateTime.now().hour}:${DateTime.now().minute}";

    await prefs.setString('time', time);

    setState(() {
      savedLocation = LatLng(
        position.latitude,
        position.longitude,
      );

      parkingTime = time;
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Parking location saved"),
      ),
    );
  }

  Future<void> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();

    double? lat = prefs.getDouble('lat');
    double? lng = prefs.getDouble('lng');
    String? time = prefs.getString('time');

    if (lat != null && lng != null) {
      setState(() {
        savedLocation = LatLng(lat, lng);
        parkingTime = time ?? "";
      });
    }
  }

  Future<void> navigateToCar() async {
    if (savedLocation == null) return;

    final url =
        'https://www.google.com/maps/search/?api=1&query=${savedLocation!.latitude},${savedLocation!.longitude}';

    await launchUrl(Uri.parse(url));
  }

  Future<void> deleteLocation() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('lat');
    await prefs.remove('lng');
    await prefs.remove('time');

    setState(() {
      savedLocation = null;
      parkingTime = "";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Location deleted"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Parking My Car"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.toggleTheme,
            icon: Icon(
              widget.darkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Container(
                    margin: const EdgeInsets.all(15),
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.cyan,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_parking,
                        color: Colors.white,
                        size: 120,
                      ),
                    ),
                  )
                      .animate()
                      .fade(duration: 800.ms)
                      .slideY(begin: -1),

                  if (savedLocation != null)
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(25),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                "Saved Parking Location",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 15),

                              Text(
                                "Latitude: ${savedLocation!.latitude}",
                              ),

                              Text(
                                "Longitude: ${savedLocation!.longitude}",
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "Saved at: $parkingTime",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  buildButton(
                    title: "Save Parking Location",
                    color: Colors.blue,
                    icon: Icons.save,
                    onTap: saveParkingLocation,
                  ),

                  buildButton(
                    title: "Navigate To My Car",
                    color: Colors.green,
                    icon: Icons.navigation,
                    onTap: navigateToCar,
                  ),

                  buildButton(
                    title: "Delete Location",
                    color: Colors.red,
                    icon: Icons.delete,
                    onTap: deleteLocation,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 350,
                    child: savedLocation == null
                        ? const Center(
                            child: Text(
                              "No saved location",
                              style: TextStyle(fontSize: 20),
                            ),
                          )
                        : Padding(
                            padding:
                                const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(25),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter:
                                      savedLocation!,
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point:
                                            savedLocation!,
                                        width: 80,
                                        height: 80,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildButton({
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          title,
          style: const TextStyle(fontSize: 18),
        ),
      )
          .animate()
          .fade(duration: 600.ms)
          .scale(),
    );
  }
}