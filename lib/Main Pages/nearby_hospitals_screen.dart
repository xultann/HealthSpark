import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Utils/theme_provider.dart'; // For ThemeProvider
import 'package:provider/provider.dart'; // For Provider
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/services.dart';

const String _darkMapStyle = '''[
  {"elementType": "geometry","stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.stroke","stylers": [{"color": "#242f3e"}]},
  {"elementType": "labels.text.fill","stylers": [{"color": "#746855"}]},
  {"featureType": "administrative.locality","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
  {"featureType": "poi","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
  {"featureType": "poi.park","elementType": "geometry","stylers": [{"color": "#263c3f"}]},
  {"featureType": "poi.park","elementType": "labels.text.fill","stylers": [{"color": "#6b9a76"}]},
  {"featureType": "road","elementType": "geometry","stylers": [{"color": "#38414e"}]},
  {"featureType": "road","elementType": "geometry.stroke","stylers": [{"color": "#212a37"}]},
  {"featureType": "road","elementType": "labels.text.fill","stylers": [{"color": "#9ca5b3"}]},
  {"featureType": "road.highway","elementType": "geometry","stylers": [{"color": "#746855"}]},
  {"featureType": "road.highway","elementType": "geometry.stroke","stylers": [{"color": "#1f2835"}]},
  {"featureType": "road.highway","elementType": "labels.text.fill","stylers": [{"color": "#f3d19c"}]},
  {"featureType": "transit","elementType": "geometry","stylers": [{"color": "#2f3948"}]},
  {"featureType": "transit.station","elementType": "labels.text.fill","stylers": [{"color": "#d59563"}]},
  {"featureType": "water","elementType": "geometry","stylers": [{"color": "#17263c"}]},
  {"featureType": "water","elementType": "labels.text.fill","stylers": [{"color": "#515c6d"}]},
  {"featureType": "water","elementType": "labels.text.stroke","stylers": [{"color": "#17263c"}]}
]''';
const String _lightMapStyle = '';

class NearbyHospitalsScreen extends StatefulWidget {
  const NearbyHospitalsScreen({super.key});

  @override
  State<NearbyHospitalsScreen> createState() => _NearbyHospitalsScreenState();
}

class _NearbyHospitalsScreenState extends State<NearbyHospitalsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _permissionDenied = false;
  String _selectedCategory = 'Hospitals';
  List<Map<String, dynamic>> _nearbyPlaces = [];
  
  // Health facility types
  final List<String> _categories = ['Hospitals', 'Clinics', 'Pharmacies', 'Dental', 'All'];
  
  double _currentZoom = 14;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  
  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied || 
            requestPermission == LocationPermission.deniedForever) {
          setState(() {
            _permissionDenied = true;
            _isLoading = false;
          });
          return;
        }
      }
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      // Once we have the position, find nearby health facilities
      await _findNearbyHealthFacilities();
      
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error getting location. Please check your location settings.')),
        );
      }
    }
  }
  
  // In a real app, we would use Google Places API to find nearby health facilities
  Future<List<Map<String, dynamic>>> fetchPlacesForKeyword(String keyword, String categoryLabel) async {
    final apiKey = 'AIzaSyA8ZxleQedeIiY8XbejqXVn-8mllzQ9tug';
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    print('Fetching places for "$keyword" at $lat, $lng');
    // Change radius to 5000 meters (5 km)
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&keyword=$keyword&key=$apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final List results = data['results'];
        return results.map<Map<String, dynamic>>((place) {
          return {
            'name': place['name'] ?? '',
            'address': place['vicinity'] ?? '',
            'rating': place['rating'] ?? 0.0,
            'type': categoryLabel,
            'lat': place['geometry']['location']['lat'],
            'lng': place['geometry']['location']['lng'],
          };
        }).toList();
      } else {
        print('Places API error: ${data['status']} - ${data['error_message'] ?? ''}');
      }
    }
    return [];
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    // Recenter the map to the user's current location
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
    _findNearbyHealthFacilities();
  }

  Future<void> _findNearbyHealthFacilities() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> places = [];
      if (_selectedCategory == 'All') {
        // Fetch all keywords in parallel
        final results = await Future.wait([
          fetchPlacesForKeyword('hospital', 'Hospitals'),
          fetchPlacesForKeyword('clinic', 'Clinics'),
          fetchPlacesForKeyword('pharmacy', 'Pharmacies'),
          fetchPlacesForKeyword('dentist', 'Dental'),
        ]);
        // Combine and deduplicate by name+address
        final seen = <String>{};
        for (var list in results) {
          for (var place in list) {
            final key = place['name'] + place['address'];
            if (!seen.contains(key)) {
              seen.add(key);
              places.add(place);
            }
          }
        }
      } else {
        String keyword;
        String label = _selectedCategory;
        switch (_selectedCategory) {
          case 'Hospitals':
            keyword = 'hospital';
            break;
          case 'Clinics':
            keyword = 'clinic';
            break;
          case 'Pharmacies':
            keyword = 'pharmacy';
            break;
          case 'Dental':
            keyword = 'dentist';
            break;
          default:
            keyword = 'hospital';
        }
        places = await fetchPlacesForKeyword(keyword, label);
      }
      setState(() {
        _nearbyPlaces = places;
        _updateMapMarkers();
        _isLoading = false;
      });
      if (places.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No places found.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching places: $e')),
        );
      }
    }
  }
  
  // Update markers on the map based on selected category
  void _updateMapMarkers() {
    Set<Marker> markers = {};
    
    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    
    // Add markers for health facilities based on the selected category
    for (final place in _nearbyPlaces) {
      if (_selectedCategory == 'All' || place['type'] == _selectedCategory) {
        markers.add(
          Marker(
            markerId: MarkerId(place['name']),
            position: LatLng(place['lat'], place['lng']),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: place['address'],
            ),
            onTap: () {
              _showPlaceDetails(place);
            },
          ),
        );
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  // Show details of the selected place
  void _showPlaceDetails(Map<String, dynamic> place) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final sheetBg = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : Colors.black;
    final orange = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: DefaultTextStyle(
            style: TextStyle(color: textColor),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place['address'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            place['rating'].toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        place['type'],
                        style: TextStyle(
                          color: orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.directions,
                      label: 'Directions',
                      onTap: () {
                        _openInGoogleMaps(place);
                        Navigator.pop(context);
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.call,
                      label: 'Call',
                      onTap: () async {
                        final phone = place['phone'] ?? '';
                        if (phone.isNotEmpty) {
                          await Clipboard.setData(ClipboardData(text: phone));
                          _launchCall(phone);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Phone number copied and dialer opened.')),
                            );
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No phone number available.')),
                            );
                          }
                        }
                        Navigator.pop(context);
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onTap: () async {
                        final lat = place['lat'];
                        final lng = place['lng'];
                        final name = Uri.encodeComponent(place['name']);
                        final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng($name)';
                        await Clipboard.setData(ClipboardData(text: url));
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Location link copied to clipboard!')),
                          );
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final orange = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, color: orange), // Use theme orange for action icons
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
  
  // Open Google Maps with directions to the location
  Future<void> _openInGoogleMaps(Map<String, dynamic> place) async {
    final lat = place['lat'];
    final lng = place['lng'];
    final name = place['name'];
    final encodedName = Uri.encodeComponent(name);
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$encodedName';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening maps: $e')),
        );
      }
    }
  }
  
  // Launch phone dialer
  Future<void> _launchCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme info from ThemeProvider (like dashboard)
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    return Scaffold(
      body: _permissionDenied 
        ? _buildPermissionDeniedView()
        : Column(
            children: [
              // Filter chips at the top (like medical info screen)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.05 * 255).toInt()),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color: isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _onCategorySelected(category);
                            }
                          },
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          selectedColor: isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange).withAlpha((0.2 * 255).toInt()) : const Color(0xFFFF7F27).withAlpha((0.2 * 255).toInt()),
                          checkmarkColor: isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Map and bottom sheet
              Expanded(
                child: Stack(
                  children: [
                    // Map
                    _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMap(),
                    
                    // Bottom list of places (must be last to be on top)
                    _buildBottomSheet(),
                  ],
                ),
              ),
            ],
          ),
    );
  }
  
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              'Location Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We need access to your location to show nearby hospitals and medical facilities.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text('Grant Permission'),
              onPressed: () async {
                final status = await Permission.location.request();
                if (status.isGranted) {
                  setState(() {
                    _permissionDenied = false;
                    _isLoading = true;
                  });
                  _getCurrentLocation();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMap() {
    if (_currentPosition == null) {
      return const Center(child: Text('Getting your location...'));
    }
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: _currentZoom,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // Hide built-in recenter button
          zoomControlsEnabled: false, // Hide built-in zoom controls
          onMapCreated: (controller) async {
            setState(() {
              _mapController = controller;
            });
            // Set map style based on theme
            await controller.setMapStyle(isDark ? _darkMapStyle : _lightMapStyle);
          },
          onCameraMove: (position) {
            _currentZoom = position.zoom;
          },
        ),
        // Custom zoom and recenter buttons at top left
        Positioned(
          top: 16,
          left: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                backgroundColor: isDark ? Colors.deepOrange[700] : const Color(0xFFFF7F27),
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  _currentZoom += 1;
                  _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                backgroundColor: isDark ? Colors.deepOrange[700] : const Color(0xFFFF7F27),
                child: const Icon(Icons.remove, color: Colors.white),
                onPressed: () {
                  _currentZoom -= 1;
                  _mapController?.animateCamera(CameraUpdate.zoomTo(_currentZoom));
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'recenter',
                mini: true,
                backgroundColor: isDark ? Colors.deepOrange[700] : const Color(0xFFFF7F27),
                onPressed: () {
                  if (_currentPosition != null && _mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      ),
                    );
                  }
                },
                tooltip: 'Recenter',
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
  

  
  Widget _buildBottomSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final orange = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    final filteredPlaces = _nearbyPlaces.where((place) {
      return _selectedCategory == 'All' || place['type'] == _selectedCategory;
    }).toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.1,
      maxChildSize: 0.7,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                controller: scrollController,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    height: 4,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: orange, // Use theme color
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '${filteredPlaces.length} $_selectedCategory Nearby',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: orange,
                      ),
                    ),
                  ),
                  // List of places
                  if (filteredPlaces.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text(
                          'No $_selectedCategory found nearby.\nTry changing the filter or searching in a different area.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ...filteredPlaces.map((place) => Card(
                          color: isDark ? Colors.grey[850] : Colors.white,
                          child: ListTile(
                            title: Text(place['name'], style: TextStyle(color: orange, fontWeight: FontWeight.bold)),
                            subtitle: Text(place['address'], style: TextStyle(color: isDark ? Colors.deepOrange[200] : Colors.grey[700])),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    place['rating'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: orange.withOpacity(0.1),
                              child: Icon(
                                _getIconForType(place['type']),
                                color: orange,
                              ),
                            ),
                            onTap: () {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(place['lat'], place['lng']),
                                ),
                              );
                              _showPlaceDetails(place);
                            },
                          ),
                        )),
                ],
              ),
        );
      },
    );
  }
  
  IconData _getIconForType(String type) {
    switch (type) {
      case 'Hospitals':
        return Icons.local_hospital;
      case 'Clinics':
        return Icons.medical_services;
      case 'Pharmacies':
        return Icons.local_pharmacy;
      case 'Dental':
        return Icons.cleaning_services;
      default:
        return Icons.health_and_safety;
    }
  }
}