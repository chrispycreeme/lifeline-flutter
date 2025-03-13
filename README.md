# Lifeline

Lifeline is a mobile application designed to assist users in navigating to various markers on a map. The app provides real-time location updates, route planning, and offline route caching. It is built using Flutter and leverages several APIs and libraries to provide its functionality.

## Features

- **Real-time Location Tracking**: The app tracks the user's current location and updates the map accordingly.
- **Marker Information**: Users can tap on markers to view detailed information about each location.
- **Route Planning**: The app calculates and displays the route from the user's current location to the selected marker.
- **Offline Route Caching**: Routes are cached for offline use, ensuring that users can navigate even without an internet connection.
- **Connectivity Check**: The app checks for internet connectivity and adjusts its behavior based on the connection status.

## APIs and Libraries Used

- **Flutter**: The app is built using the Flutter framework.
- **Flutter Map**: A map widget for Flutter, used to display the map and markers.
- **Geolocator**: A Flutter plugin for accessing geolocation information.
- **OSRM (Open Source Routing Machine)**: Used for route planning and navigation.
- **Sqflite**: A Flutter plugin for SQLite, used for local database storage.
- **Path Provider**: A Flutter plugin for finding commonly used locations on the filesystem.
- **Permission Handler**: A Flutter plugin for handling permissions.
- **Connectivity Plus**: A Flutter plugin for checking internet connectivity.
- **Cached Network Image**: A Flutter library for loading and caching network images.

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/yourusername/lifeline.git
    ```
2. Navigate to the project directory:
    ```sh
    cd lifeline
    ```
3. Install the dependencies:
    ```sh
    flutter pub get
    ```
4. Run the app:
    ```sh
    flutter run
    ```

## Usage

1. **View Marker Information**: Tap on a marker to view its information.
2. **Change Route**: Use the "Change Route" button to select a different marker to route to.
3. **View Usage Instructions**: Tap the "Usage Instructions" button for a quick guide on how to use the app.

## Permissions

The app requires the following permissions:
- **Location**: To track the user's current location.
- **Internet**: To fetch map tiles and route information.

## Process of the System

[![](https://mermaid.ink/img/pako:eNplVc1u20YQfpUBgQQ2IBu1fkJZhwa2pNpypFgR7RQN5cOGHJoLU7ssd2VHEX1LbykawDkVDXLLpS_Qvk5foHmEzu5SP0Fvq935Zr5v5htq6UUyRq_jXRcsT-GiNxUAjx5BoFmhgYkYBoJrzjL-lmkuhXk-2gnt89Uu7O19Xx7lOWRsLqIUVQnH4RqAQE8ZjyzwyiCPHUDdQCILOBkHwKIIFcG64QR_nqPSMJQOAGMsZlwph61obe7glMhlXFybl67N-88fv2wHnBRMaIxL6IVDrjQK0HKT_TKPmUZ1tQX_9H4b3kPBDbofBqm8g35REOXH0H_DtQX1LajLhJAa8kJGiDHccZ3KuYasKlPCq52wL-Kr3bWEborRDXSlEBhpfsv1wjz0XDb7xhOYKyyAK5CCJGIJJ8sBaSkEaji6ZTxjrzN8er_OeW7DYESjhD34AXWUEtUuo5FAj2lmwk5sha-f33-An1B1tjElnIZDyWIYseIGC0VYl2NCWtCqPbXoAMkQlttKIIXGNDUuKrmD9RwtFpJCzuA8mIzgaDywmQY20wQj5LcIMtd8RlaJoTDxJZyFPa7yjC2qBFRixPKNA4womro10HmSWA2XCrc4Mko7s0LWLMlgz0LXjo1El3ZFyMIsByBjsBKGFWDTg2cuUMsCbeYsW1gasqJBjSGzHYc7Xz8_fFmTM_13o9i1WYYmC4VthlcFVtMjMS48_t_ofv8TnsvON4ASRm50WxBbZmQxJpkiZXHVEVWrND6mi7y0NMh8bi-tz5WRt5nGmuWlmbo1IYtsS8392aoImbV6UnYHQKfoKoyXP6ZMQyxR2UvrnjvaTLONsTQmBhi7BXz3979__QYvOd6tBshFIkt44VbQjY4WU9MGuM0dV535-I72iolrXBGfhAFmtGDQ40mCBQq9Nciq3KcHeG6WNsUsf1pC4KpcKkZpBkLpYu6UflPp4Vcg77Ismmf0_ViVuwjd92RdpOraUMpcwTGjrSa55Dhzf7HagHWW10wRD7K6IOnOfmcm8oX1ij1ONsdgdfRq3ow-WIzH9AFfmqepRz2e4dTr0DHGhM0zPfWm4p5C2VzLYCEir0PKsOYR9evU6yQsU_Rrbvn3OKM_gtkqJGfilZTbP73O0nvjdeoHh_v1etNvt_2W32i2n9S8Bd36-_XGYbPVarTaB77vN57c17y3NsF3-4cHrWbLr1Ns2_ebzcb9fxXAMCs?type=png)](https://mermaid.live/edit#pako:eNplVc1u20YQfpUBgQQ2IBu1fkJZhwa2pNpypFgR7RQN5cOGHJoLU7ssd2VHEX1LbykawDkVDXLLpS_Qvk5foHmEzu5SP0Fvq935Zr5v5htq6UUyRq_jXRcsT-GiNxUAjx5BoFmhgYkYBoJrzjL-lmkuhXk-2gnt89Uu7O19Xx7lOWRsLqIUVQnH4RqAQE8ZjyzwyiCPHUDdQCILOBkHwKIIFcG64QR_nqPSMJQOAGMsZlwph61obe7glMhlXFybl67N-88fv2wHnBRMaIxL6IVDrjQK0HKT_TKPmUZ1tQX_9H4b3kPBDbofBqm8g35REOXH0H_DtQX1LajLhJAa8kJGiDHccZ3KuYasKlPCq52wL-Kr3bWEborRDXSlEBhpfsv1wjz0XDb7xhOYKyyAK5CCJGIJJ8sBaSkEaji6ZTxjrzN8er_OeW7DYESjhD34AXWUEtUuo5FAj2lmwk5sha-f33-An1B1tjElnIZDyWIYseIGC0VYl2NCWtCqPbXoAMkQlttKIIXGNDUuKrmD9RwtFpJCzuA8mIzgaDywmQY20wQj5LcIMtd8RlaJoTDxJZyFPa7yjC2qBFRixPKNA4womro10HmSWA2XCrc4Mko7s0LWLMlgz0LXjo1El3ZFyMIsByBjsBKGFWDTg2cuUMsCbeYsW1gasqJBjSGzHYc7Xz8_fFmTM_13o9i1WYYmC4VthlcFVtMjMS48_t_ofv8TnsvON4ASRm50WxBbZmQxJpkiZXHVEVWrND6mi7y0NMh8bi-tz5WRt5nGmuWlmbo1IYtsS8392aoImbV6UnYHQKfoKoyXP6ZMQyxR2UvrnjvaTLONsTQmBhi7BXz3979__QYvOd6tBshFIkt44VbQjY4WU9MGuM0dV535-I72iolrXBGfhAFmtGDQ40mCBQq9Nciq3KcHeG6WNsUsf1pC4KpcKkZpBkLpYu6UflPp4Vcg77Ismmf0_ViVuwjd92RdpOraUMpcwTGjrSa55Dhzf7HagHWW10wRD7K6IOnOfmcm8oX1ij1ONsdgdfRq3ow-WIzH9AFfmqepRz2e4dTr0DHGhM0zPfWm4p5C2VzLYCEir0PKsOYR9evU6yQsU_Rrbvn3OKM_gtkqJGfilZTbP73O0nvjdeoHh_v1etNvt_2W32i2n9S8Bd36-_XGYbPVarTaB77vN57c17y3NsF3-4cHrWbLr1Ns2_ebzcb9fxXAMCs)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## Contact

For any inquiries, please contact [yourname@example.com](mailto:yourname@example.com).