import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'model/Lokasi.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key:key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'MapProject'),
    );
  }
}

class HomePage extends StatefulWidget{
  const HomePage({Key? key, required this.title}) : super(key:key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  LocationData? currentLocation;
  Location location = Location();

  List<Marker> allMarker = [];
  late FollowOnLocationUpdate _followOnLocationUpdate;

  bool isLoading = true;
  bool isManuaMarkerAdditionMode = false;

  double Zoom = 10.0;
  late MapController mapController;

  String? tappedlatitude;
  String? tappedLongitude;

  Future<void> _fetchMarkersFromApi() async {
    try{
      const apiUrl = 'http://10.0.2.2/SlimAPI/public/mapproject/72210454/';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200){
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        if(jsonData.containsKey('data')&&jsonData['data'] is List){
          final List<dynamic> data = jsonData['data'];

          setState(() {
            allMarker.clear();

            for(final MarkerL in data){
              try{
                final String lat = MarkerL['lat'].toString();
                final String long = MarkerL['long'].toString();
                final String detail = MarkerL['detail'];

                allMarker.add(_Marker(
                  double.parse(lat), double.parse(long), detail));
              } catch(e){}
            }
          });
        }
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Marker _Marker(double lat, double long, String detail){
    return Marker(
      width: 100.0,
        height: 100.0,
        point: LatLng(lat, long),
        child: IconButton(
          onPressed: (){
            _showLocationDialog(lat, long, detail);
          },
          icon: Image.asset(
            'images/location-2955.png',
            width: 20,
            height: 20,
          )
        )
    );
  }

  void _showLocationDialog(
      double lat, double long, String detail
      ){
    showDialog(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.greenAccent),
                    const SizedBox(width: 8,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$lat, $long',
                        style: const TextStyle(fontWeight: FontWeight.normal),)
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children:[
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 8,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail),
                    ],
                  ),
                ],
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: (){
                    Navigator.of(context).pop();
              },
                  child: const Text("X"),
              ),
            ],
          );
    },
    );
  }

  Future<void> _getLocation() async {
    try {
      currentLocation = await location.getLocation();
      setState(() {
        _fetchMarkersFromApi();
      });
      // ignore: empty_catches
    } catch (e) {}
  }


  void _addMarker(LatLng tappedPoint) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Lokasi lokasi = Lokasi(
          detail: "",
          lat: tappedPoint.latitude,
          long: tappedPoint.longitude,
        );

        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: "Detail Lokasi",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  lokasi.detail = value;
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Create a marker and add it to the map
                  Marker newMarker = _Marker(
                    tappedPoint.latitude,
                    tappedPoint.longitude,
                    lokasi.detail,
                  );

                  setState(() {
                    allMarker.add(newMarker);
                  });

                  // Save the data to the API
                  await _sendDataToApi(lokasi);
                  await _fetchMarkersFromApi();

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                  // ignore: empty_catches
                } catch (e) {
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                "Save",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleManualMarkerAdditionMode() {
    setState(() {
      isManuaMarkerAdditionMode = !isManuaMarkerAdditionMode;
    });

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isManuaMarkerAdditionMode
                ? Icons.add_location
                : Icons.location_off,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isManuaMarkerAdditionMode
                ? "Tambah Marker"
                : "Tambah Marker dinonaktifkan.",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
      backgroundColor: isManuaMarkerAdditionMode ? Colors.green : Colors.red,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _sendDataToApi(Lokasi Lokasi) async {}

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _followOnLocationUpdate = FollowOnLocationUpdate.once;
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (currentLocation != null)
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                onTap: (tapPosition, tapLatlng) {
                  if (isManuaMarkerAdditionMode) {
                    _addMarker(tapLatlng);
                  } else {
                    setState(() {
                      tappedlatitude = tapLatlng.latitude.toStringAsFixed(6);
                      tappedLongitude = tapLatlng.longitude.toStringAsFixed(6);
                    });
                  }
                },
                initialCenter: LatLng(
                  currentLocation!.latitude ?? 0.0,
                  currentLocation!.longitude ?? 0.0,
                ),
                initialZoom: Zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  tileSize: 256,
                ),
                CurrentLocationLayer(
                  followOnLocationUpdate: _followOnLocationUpdate,
                ),
                MarkerLayer(markers: allMarker),
              ],
            ),
          Card(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Koordinat Lokasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (tappedlatitude != null && tappedLongitude != null)
                            Text(
                              'Latitude: $tappedlatitude, Longitude: $tappedLongitude',
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            )
                          else
                            const Text(
                              'Koordinat tidak tersedia. Ketuk peta.',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleManualMarkerAdditionMode,
        label: Text(
          isManuaMarkerAdditionMode
              ? "Nonaktifkan Tambah Marker"
              : "Tambah Marker",
        ),
        icon: Icon(
          isManuaMarkerAdditionMode
              ? Icons.location_off_rounded
              : Icons.add_location,
        ),
        backgroundColor: isManuaMarkerAdditionMode ? Colors.red : Colors.white,
      ),
    );
  }
}