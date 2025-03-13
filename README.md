# Lifeline Map Application

## Research Methodology

### Overview

The Lifeline Map Application is a Flutter-based mobile application designed to assist users in locating nearby evacuation centers and navigating to them. The application leverages various technologies and methodologies to provide accurate and efficient location-based services.

### Technologies Used

1. **Flutter**: The primary framework used for building the cross-platform mobile application.
2. **Dart**: The programming language used in conjunction with Flutter.
3. **Flutter Map**: A Flutter plugin used to display interactive maps.
4. **Geolocator**: A package used to access the device's location services.
5. **HTTP**: Used for making HTTP requests to fetch route data.
6. **SQLite (sqflite)**: Used for local database storage to cache routes and markers for offline use.
7. **Permission Handler**: Used to request and manage permissions for location services.
8. **Connectivity Plus**: Used to monitor network connectivity status.
9. **Flutter Cache Manager**: Used to cache network images for map tiles.
10. **Cached Network Image**: Used to display cached network images.

### Key Functionalities

1. **Location Services**:
   - The application requests location permissions from the user.
   - It listens to location updates and displays the user's current location on the map.

2. **Markers and Routes**:
   - The application loads markers representing evacuation centers from a local SQLite database.
   - It calculates and displays the route from the user's current location to the nearest marker or a manually selected marker.
   - Routes are fetched from the OSRM (Open Source Routing Machine) API.

3. **Offline Support**:
   - Routes and markers are cached in a local SQLite database for offline use.
   - The application loads cached routes and markers when there is no internet connectivity.

4. **Connectivity Monitoring**:
   - The application monitors network connectivity and updates routes accordingly.
   - It uses the Connectivity Plus package to listen for connectivity changes.

5. **User Interface**:
   - The application provides a user-friendly interface with interactive maps, markers, and route information.
   - Users can view detailed information about each marker, including distance, address, type, contact information, and barangay captain.

### Methodology

1. **Initialization**:
   - The application initializes by requesting location permissions and loading cached routes and markers.
   - It checks network connectivity and loads offline routes if available.

2. **Location Updates**:
   - The application listens to location updates and updates the user's current position on the map.
   - It periodically finds the nearest marker and updates the route accordingly.

3. **Route Calculation**:
   - The application fetches routes from the OSRM API based on the user's current location and the selected marker.
   - It caches the fetched routes in a local SQLite database for offline use.

4. **Marker Information**:
   - Users can tap on markers to view detailed information about the evacuation center.
   - The application displays a modal bottom sheet with information such as distance, address, type, contact information, and barangay captain.

5. **User Interaction**:
   - Users can manually select a different marker to route to using the "Change Route" button.
   - The application updates the route and displays the new route on the map.

## Conclusion

The Lifeline Map Application combines various technologies and methodologies to provide a robust and user-friendly solution for locating and navigating to nearby evacuation centers. By leveraging Flutter, SQLite, and various packages, the application ensures accurate location-based services and offline support for users.