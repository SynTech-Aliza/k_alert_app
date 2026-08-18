import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showAlertView = false;
  final MapController _mapController = MapController();

  LatLng _currentPosition = const LatLng(0, 0);
  bool _hasLocation = false;
  bool _isLoading = false;
  String _statusMessage = "Press the button below to display your location";

  @override
  void initState() {
    super.initState();

    // 🔴 CHANGE THIS DURATION TO MAKE THE NAVY BLUE ANIMATION FASTER OR SLOWER:
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5), // Slowed down to 5 seconds
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 3.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // GPS Location Request
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Fetching GPS coordinates...";
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Location services are disabled on your device.";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _statusMessage = "Location permission was denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Location permissions are permanently denied.";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentPosition = userLatLng;
      _hasLocation = true;
      _isLoading = false;
      _statusMessage =
          "Lat: ${position.latitude.toStringAsFixed(5)}, Lng: ${position.longitude.toStringAsFixed(5)}";
    });

    _mapController.move(userLatLng, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 1: Background Image (image_1.png)
          Positioned.fill(
            child: Image.asset(
              'assets/image_1.png',
              fit: BoxFit.cover,
            ),
          ),

          // LAYER 2: Expanding Navy Blue Circle Animation
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: screenSize.width,
                    height: screenSize.width,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0A192F).withValues(alpha: 0.92),
                    ),
                  ),
                ),
              );
            },
          ),

          // LAYER 3: Main UI Content (Fades in over animation)
          FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _showAlertView
                      // VIEW 2: MAP & LOCATION BUTTON
                      ? Column(
                          key: const ValueKey("MapView"),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _showAlertView = false;
                                    });
                                  },
                                ),
                                const Text(
                                  'Emergency Map',
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _currentPosition,
                                    initialZoom: 3.0,
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.k_alert_app',
                                    ),
                                    if (_hasLocation)
                                      MarkerLayer(
                                        markers: [
                                          Marker(
                                            point: _currentPosition,
                                            width: 50,
                                            height: 50,
                                            child: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 45,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _statusMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed:
                                    _isLoading ? null : _getCurrentLocation,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.my_location,
                                        color: Colors.white),
                                label: Text(
                                  _isLoading
                                      ? "Locating..."
                                      : "Display Current Location",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      // VIEW 1: HELLO WORLD + ALERT BUTTON
                      : Column(
                          key: const ValueKey("HomeView"),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            const Text(
                              'Hello World!',
                              style: TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              height: 80,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showAlertView = true;
                                  });
                                },
                                child: const Text(
                                  'DANGER ALERT',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}