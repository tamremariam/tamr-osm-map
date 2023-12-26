// Align(
//   alignment: Alignment.topCenter,
//   child: Padding(
//     padding: const EdgeInsets.all(35.0),
//     child: Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.5),
//             spreadRadius: 2,
//             blurRadius: 3,
//             offset: Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           TextField(
//             controller: _searchController,
//             onChanged: (String value) {
//               if (_debounce?.isActive ?? false) {
//                 _debounce?.cancel();
//               }

//               // Show loading indicator while searching
//               setState(() {
//                 _isLoading = true;
//               });

//               _debounce = Timer(const Duration(milliseconds: 2000), () async {
//                 // ... (Your existing code for fetching search results)

//                 // Hide loading indicator after search is complete
//                 setState(() {
//                   _isLoading = false;
//                 });
//               });
//             },
//             decoration: InputDecoration(
//               hintText: 'Search...',
//               contentPadding: EdgeInsets.all(12),
//               border: InputBorder.none,
//               suffixIcon: _searchController.text.isNotEmpty
//                   ? IconButton(
//                       onPressed: () {
//                         // Trigger search functionality here
//                         setState(() {
//                           _searchController.clear();
//                         });

//                         if (_debounce?.isActive ?? false) {
//                           _debounce?.cancel();
//                         }

//                         _debounce =
//                             Timer(const Duration(milliseconds: 2000), () async {
//                           if (kDebugMode) {
//                             print(_searchController.text);
//                           }
//                           var client = http.Client();
//                           try {
//                             String url =
//                                 '$baseUri/search?q=$_searchController.text&format=json&polygon_geojson=1&addressdetails=1';
//                             if (kDebugMode) {
//                               print(url);
//                             }
//                             var response = await client.get(Uri.parse(url));
//                             // var response = await client.post(Uri.parse(url));
//                             var decodedResponse = jsonDecode(
//                                     utf8.decode(response.bodyBytes))
//                                 as List<dynamic>;
//                             if (kDebugMode) {
//                               print(decodedResponse);
//                             }
//                             _options = decodedResponse
//                                 .map(
//                                   (e) => OSMdata(
//                                     displayname: e['display_name'],
//                                     lat: double.parse(e['lat']),
//                                     lon: double.parse(e['lon']),
//                                   ),
//                                 )
//                                 .toList();
//                             setState(() {});
//                           } finally {
//                             client.close();
//                           }

//                           setState(() {});
//                         });

//                         print('Clear icon pressed');
//                       },
//                       icon: Icon(Icons.clear),
//                     )
//                   : _isLoading
//                       ? CircularProgressIndicator(
//                           strokeWidth: 2.0,
//                         )
//                       : IconButton(
//                           onPressed: () {
//                             // Trigger search functionality here
//                             if (_debounce?.isActive ?? false) {
//                               _debounce?.cancel();
//                             }

//                             _debounce =
//                                 Timer(const Duration(milliseconds: 2000), () async {
//                               if (kDebugMode) {
//                                 print(_searchController.text);
//                               }
//                               var client = http.Client();
//                               try {
//                                 String url =
//                                     '$baseUri/search?q=$_searchController.text&format=json&polygon_geojson=1&addressdetails=1';
//                                 if (kDebugMode) {
//                                   print(url);
//                                 }
//                                 var response = await client.get(Uri.parse(url));
//                                 // var response = await client.post(Uri.parse(url));
//                                 var decodedResponse = jsonDecode(
//                                         utf8.decode(response.bodyBytes))
//                                     as List<dynamic>;
//                                 if (kDebugMode) {
//                                   print(decodedResponse);
//                                 }
//                                 _options = decodedResponse
//                                     .map(
//                                       (e) => OSMdata(
//                                         displayname: e['display_name'],
//                                         lat: double.parse(e['lat']),
//                                         lon: double.parse(e['lon']),
//                                       ),
//                                     )
//                                     .toList();
//                                 setState(() {});
//                               } finally {
//                                 client.close();
//                               }

//                               setState(() {});
//                             });

//                             print('Search icon pressed');
//                           },
//                           icon: Icon(Icons.search),
//                         ),
//             ),
//           ),
//           StatefulBuilder(
//             builder: ((context, setState) {
//               // Sort the _options list based on distance
//               _options.sort((a, b) {
//                 double distanceA = calculateDistance(
//                   center.latitude,
//                   center.longitude,
//                   a.lat,
//                   a.lon,
//                 );
//                 double distanceB = calculateDistance(
//                   center.latitude,
//                   center.longitude,
//                   b.lat,
//                   b.lon,
//                 );
//                 return distanceA.compareTo(distanceB);
//               });

//               return ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: _options.length > 5 ? 5 : _options.length,
//                 itemBuilder: (context, index) {
//                   // Calculate the distance from the current location
//                   double distance = calculateDistance(
//                     center.latitude,
//                     center.longitude,
//                     _options[index].lat,
//                     _options[index].lon,
//                   );

//                   return ListTile(
//                     title: Text(_options[index].displayname),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                             'Coordinates: ${_options[index].lat},${_options[index].lon}'),
//                         Text('Distance: ${distance.toStringAsFixed(2)} km'),
//                       ],
//                     ),
//                     onTap: () {
//                       // Ensure that this print statement executes
//                       print('Tapped on item at index $index');

//                       // Uncomment the line below if you want to move the map
//                       // _mapController.move(
//                       //   LatLng(_options[index].lat, _options[index].lon),
//                       //   15.0,
//                       // );

//                       // Print the selected latitude and longitude
//                       print(
//                           'Selected LatLng: ${LatLng(_options[index].lat, _options[index].lon)}');

//                       _focusNode.unfocus();
//                       _options.clear();
//                       setState(() {});
//                     },
//                   );
//                 },
//               );
//             }),
//           ),
//         ],
//       ),
//     ),
//   ),
// ),