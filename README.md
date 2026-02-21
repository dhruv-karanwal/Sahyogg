<<<<<<< HEAD
# volunteer_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
# Flood_LG: Disaster Response & Liquid Galaxy Control System

**Flood_LG** is a dual-application ecosystem designed to aid in flood disaster management. It bridges the gap between disaster authorities and citizens using real-time communication, geolocation services, and **Liquid Galaxy** visualization.

## 📱 Project Components

The system consists of two Flutter applications:

### 1. Admin App (Command Center)
A powerful dashboard for disaster management authorities to coordinate efforts and visualize data on Liquid Galaxy.
*   **Liquid Galaxy Controller:** Control Google Earth on a Liquid Galaxy rig to visualize flood data, kml layers, and orbit locations.
*   **Advisory Broadcast:** Send real-time alerts (Warning, Evacuation, Information) to all citizen apps. Maintains a history of all sent advisories.
*   **Rescue Requests:** View incoming SOS calls from citizens, prioritized by severity (High/Medium/Low). Locate victims on the map.
*   **Safe Zone Management:** Create, update, and manage safe zones (shelters, hospitals) with geolocation and capacity details.

### 2. User App (Citizen Safety)
A lifeline app for citizens in flood-prone areas.
*   **Live Flood Map:** View flood risk zones and map layers.
*   **SOS Emergency:** One-tap SOS button to send location and distress signal to authorities.
*   **Advisory Banner:** Receive live scrolling alerts from the command center. View past advisory history.
*   **Safe Zone Finder:** Locate nearby relief camps and hospitals. Get directions and view details (capacity, status).

---

## 🛠 Tech Stack

*   **Frontend:** Flutter (Dart)
*   **Backend:** Firebase
    *   **Realtime Database:** Instant advisory broadcasts and Liquid Galaxy control synchronization.
    *   **Cloud Firestore:** Storage for Safe Zones and Rescue (SOS) requests.
*   **Visualization:** Liquid Galaxy (Google Earth)
*   **Maps:** Flutter Map, LatLong2, OpenRouteService (for routing).

---

## 🚀 Features & Workflow

### 🚨 Emergency Response (SOS)
1.  **Citizen** presses SOS in User App.
2.  Data (Location, timestamp) is sent to Firestore.
3.  **Admin** sees the request in "Rescue Requests" screen, sorted by urgency.
4.  Admin can "Fly To" the location on Liquid Galaxy to assess the terrain.

### 📢 Advisory System
1.  **Admin** composes a message (e.g., "Heavy rain in Sector 4, evacuate immediately").
2.  Broadcasts to Firebase Realtime Database.
3.  **User App** immediately shows a color-coded **Live Banner** (Red for Evacuation, Orange for Warning).
4.  Advisory is saved to a persistent **History Log** for citizens to review later.

### 🛡 Safe Zones
1.  **Admin** adds a shelter using "Map Pick" or coordinates in the Admin App.
2.  **User App** lists safe zones sorted by distance from the user.
3.  Users can view a route to the selected safe zone on the map.

---

## 📦 Installation & Setup

### Prerequisites
*   Flutter SDK installed (`flutter doctor`)
*   Firebase Project configured (with `google-services.json` in both apps).
*   Liquid Galaxy Rig (Optional, for visualization features).

### Steps
1.  **Clone the Repository**
    ```bash
    git clone https://github.com/dhruv-karanwal/Flood_LG.git
    cd Flood_LG
    ```

2.  **Setup Admin App**
    ```bash
    cd Admin_App
    flutter pub get
    flutter run
    ```

3.  **Setup User App**
    ```bash
    cd ../User_App
    flutter pub get
    flutter run
    ```

---

## 🌍 Liquid Galaxy Integration
The Admin App connects to the Liquid Galaxy rig via **SSH**.
*   **Connection:** Enter Rig IP, User, and Password in Settings.
*   **Controls:** Relaunch, Reboot, Shutdown, Clean KMLs.
*   **Visualization:** Push KMLs for flood layers, orbit specific coordinates, and visualize rescue clusters.

---

## 📝 License
This project is open-source.
>>>>>>> 9ae75d8067a1d503e46ec47085c796d97bb45bd1
