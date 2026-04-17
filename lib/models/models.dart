import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TouristLocation {
  final String id;
  final String name;
  final String crowdStatus;
  final String travelTime;
  final String distance;
  final String emoji;
  final Color statusColor;
  final LatLng position;
  final String description;
  final String category;
  final List<String> photos;
  final String openHours;
  final String bestTime;
  final double rating;
  final String panorama360Url;
  const TouristLocation({
    required this.id, required this.name, required this.crowdStatus,
    required this.travelTime, required this.distance, required this.emoji,
    required this.statusColor, required this.position, required this.description,
    required this.category, this.photos = const [], required this.openHours,
    required this.bestTime, this.rating = 4.5,
    this.panorama360Url = '',
  });
}
class ParkingSpot {
  final String name;
  final String address;
  final String distance;
  final int totalSlots;
  final int availableSlots;
  final String fee;
  final LatLng position;
  const ParkingSpot({
    required this.name, required this.address, required this.distance,
    required this.totalSlots, required this.availableSlots,
    required this.fee, required this.position,
  });
  double get occupancyRate => 1 - (availableSlots / totalSlots);
  Color get statusColor {
    if (occupancyRate < 0.5) return const Color(0xFF4CAF50);
    if (occupancyRate < 0.8) return const Color(0xFFFFA726);
    return const Color(0xFFE53935);
  }
  String get statusLabel {
    if (occupancyRate < 0.5) return 'Available';
    if (occupancyRate < 0.8) return 'Filling Up';
    return 'Almost Full';
  }
}
class RoadIncident {
  final String id, title, location, type, severity, timeAgo;
  final Color severityColor;
  final IconData icon;
  const RoadIncident({
    required this.id, required this.title, required this.location,
    required this.type, required this.severity, required this.timeAgo,
    required this.severityColor, required this.icon,
  });
}
class CommunityReport {
  final String id, type, location, description, timeAgo, reporterName;
  final int upvotes;
  final Color color;
  final IconData icon;
  CommunityReport({
    required this.id, required this.type, required this.location,
    required this.description, required this.upvotes, required this.timeAgo,
    required this.reporterName, required this.color, required this.icon,
  });
}
class TripStop {
  final TouristLocation location;
  String scheduledTime;
  int estimatedMinutes;
  TripStop({required this.location, required this.scheduledTime, required this.estimatedMinutes});
}
class RouteOption {
  final String id, name, duration, distance, trafficCondition;
  final Color trafficColor;
  final bool isRecommended;
  final List<String> via;
  const RouteOption({
    required this.id, required this.name, required this.duration,
    required this.distance, required this.trafficCondition,
    required this.trafficColor, this.isRecommended = false, required this.via,
  });
}
class EmergencyService {
  final String name, type, address, phone, distance;
  final IconData icon;
  final Color color;
  const EmergencyService({
    required this.name, required this.type, required this.address,
    required this.phone, required this.distance, required this.icon, required this.color,
  });
}
class AppData {
  static const List<TouristLocation> locations = [
    TouristLocation(
      id: 'burnham', name: 'Burnham Park', crowdStatus: 'Moderate', travelTime: '5 mins', distance: '1.2 km', emoji: '🏞️',
      statusColor: Color(0xFFFFA726), position: LatLng(16.4119, 120.5937),
      description: 'Burnham Park is a central park in Baguio City named after city planner Daniel Hudson Burnham. It features a man-made lake for boating, a rose garden, orchidarium, and bike rentals.',
      category: 'Park', openHours: '5:00 AM – 10:00 PM', bestTime: '7:00 AM – 9:00 AM', rating: 4.6,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipN1pHMpypkib9EoFOTmLZjkmqYE5s1P4oCwCwVL=w1920-h960',
    ),
    TouristLocation(
      id: 'mines_view', name: 'Mines View Park', crowdStatus: 'High', travelTime: '15 mins', distance: '5.8 km', emoji: '⛰️',
      statusColor: Color(0xFFE53935), position: LatLng(16.3988, 120.5960),
      description: 'Mines View Park overlooks the abandoned gold and copper mines of Benguet and the Cordillera mountain range. Popular for souvenir shopping and mountain views.',
      category: 'Viewpoint', openHours: '6:00 AM – 8:00 PM', bestTime: '6:00 AM – 8:00 AM', rating: 4.7,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipMZerp4iDLmJzIEZRHEJBHT8fvnGBnbnQHAZMf5=w1920-h960',
    ),
    TouristLocation(
      id: 'mansion', name: 'The Mansion', crowdStatus: 'Low', travelTime: '8 mins', distance: '2.5 km', emoji: '🏛️',
      statusColor: Color(0xFF4CAF50), position: LatLng(16.4154, 120.5937),
      description: 'The Mansion is the official summer residence of the President of the Philippines. Its grand wrought-iron gate is a famous photo spot with manicured gardens.',
      category: 'Heritage', openHours: '8:00 AM – 5:00 PM', bestTime: '8:00 AM – 10:00 AM', rating: 4.4,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipOjF0nBo7gkV6R8-s0V_9LKYdZ4Lsp9nqYuUdVo=w1920-h960',
    ),
    TouristLocation(
      id: 'camp_john_hay', name: 'Camp John Hay', crowdStatus: 'Low', travelTime: '10 mins', distance: '3.0 km', emoji: '🌲',
      statusColor: Color(0xFF4CAF50), position: LatLng(16.3963, 120.5779),
      description: 'A former US military facility transformed into a leisure destination with a golf course, pine forest walks, hotels, restaurants, and Tree Top Adventure.',
      category: 'Recreation', openHours: '6:00 AM – 10:00 PM', bestTime: '7:00 AM – 9:00 AM', rating: 4.8,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipO_5HkFt_pHXBIbEEv5jBqJTHTbxMxpRi2XYIZ-=w1920-h960',
    ),
    TouristLocation(
      id: 'good_shepherd', name: 'Good Shepherd Convent', crowdStatus: 'Low', travelTime: '12 mins', distance: '3.4 km', emoji: '⛪',
      statusColor: Color(0xFF4CAF50), position: LatLng(16.3964, 120.5779),
      description: 'Famous for its ube jam and delicacies made by the sisters. Popular for authentic Baguio pasalubong including strawberry jam and peanut brittle.',
      category: 'Shopping', openHours: '7:00 AM – 5:00 PM', bestTime: '7:00 AM – 9:00 AM', rating: 4.5,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipNkxwzL6pTIGy9g0Lf9APcTx3VaFvnXfnJpHHJY=w1920-h960',
    ),
    TouristLocation(
      id: 'session_road', name: 'Session Road', crowdStatus: 'High', travelTime: '3 mins', distance: '0.8 km', emoji: '🛍️',
      statusColor: Color(0xFFE53935), position: LatLng(16.4090, 120.5970),
      description: 'The main commercial street of Baguio City lined with restaurants, cafes, shops, and entertainment. Famous for street food and strawberry taho.',
      category: 'Commercial', openHours: 'Open 24 Hours', bestTime: '8:00 AM – 10:00 AM', rating: 4.3,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipNpJYOGH8Kik1ZaglV_rJJxRFq74Pf8RaNF_mVl=w1920-h960',
    ),
    TouristLocation(
      id: 'baguio_night_market', name: 'Baguio Night Market', crowdStatus: 'Moderate', travelTime: '5 mins', distance: '1.5 km', emoji: '🌙',
      statusColor: Color(0xFFFFA726), position: LatLng(16.4080, 120.5960),
      description: 'Friday to Sunday night market on Harrison Road selling ukay-ukay, local delicacies, handicrafts, and souvenirs at bargain prices.',
      category: 'Market', openHours: 'Fri–Sun: 9:00 PM – 2:00 AM', bestTime: '9:00 PM – 11:00 PM', rating: 4.4,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipMKbdT8QhH4qC8JJzBmqBBNxcuONFxR1OAkxsv0=w1920-h960',
    ),
    TouristLocation(
      id: 'botanical', name: 'Botanical Garden', crowdStatus: 'Low', travelTime: '7 mins', distance: '2.0 km', emoji: '🌺',
      statusColor: Color(0xFF4CAF50), position: LatLng(16.4140, 120.5920),
      description: 'Features plants native to the Cordillera region and an Igorot village exhibit. A peaceful retreat showcasing indigenous culture and plant life.',
      category: 'Nature', openHours: '6:00 AM – 6:00 PM', bestTime: '6:00 AM – 8:00 AM', rating: 4.2,
      panorama360Url: 'https://lh5.googleusercontent.com/p/AF1QipO4s0hPT_VRxAj4LlNxJP4b5Jm0Wr0xC5SiEbS=w1920-h960',
    ),
  ];
  static const List<ParkingSpot> parkingSpots = [
    ParkingSpot(name: 'SM City Baguio Parking', address: 'SM City Baguio, Upper Session Road', distance: '0.5 km', totalSlots: 800, availableSlots: 120, fee: '₱50/hr', position: LatLng(16.4166, 120.5995)),
    ParkingSpot(name: 'Session Road Parking', address: 'Session Road, Baguio City', distance: '0.3 km', totalSlots: 200, availableSlots: 45, fee: '₱30/hr', position: LatLng(16.4090, 120.5960)),
    ParkingSpot(name: 'Burnham Park Parking', address: 'Jose Abad Santos Drive, Baguio', distance: '1.2 km', totalSlots: 350, availableSlots: 180, fee: '₱40/hr', position: LatLng(16.4119, 120.5937)),
    ParkingSpot(name: 'Mines View Parking Area', address: 'Mines View Park, Baguio City', distance: '5.8 km', totalSlots: 150, availableSlots: 10, fee: '₱50/hr', position: LatLng(16.3988, 120.5960)),
    ParkingSpot(name: 'Camp John Hay Parking', address: 'Camp John Hay, Baguio City', distance: '3.0 km', totalSlots: 500, availableSlots: 280, fee: '₱60/hr', position: LatLng(16.3963, 120.5779)),
    ParkingSpot(name: 'Maharlika Livelihood Center', address: 'Magsaysay Ave, Baguio City', distance: '0.9 km', totalSlots: 100, availableSlots: 55, fee: '₱25/hr', position: LatLng(16.4100, 120.5940)),
  ];
  static List<RoadIncident> incidents = [
    RoadIncident(id: '1', title: 'Road Closure at The Mansion Gate', location: 'Leonard Wood Road near The Mansion', type: 'Road Closure', severity: 'High', timeAgo: '15 mins ago', severityColor: Color(0xFFE53935), icon: Icons.block),
    RoadIncident(id: '2', title: 'Heavy Traffic – Session Road', location: 'Session Road (Whole stretch)', type: 'Traffic Jam', severity: 'High', timeAgo: '5 mins ago', severityColor: Color(0xFFE53935), icon: Icons.traffic),
    RoadIncident(id: '3', title: 'Road Construction – Kennon Road', location: 'Kennon Road near Camp 3', type: 'Construction', severity: 'Moderate', timeAgo: '2 hrs ago', severityColor: Color(0xFFFFA726), icon: Icons.construction),
    RoadIncident(id: '4', title: 'Landslide Warning – Naguilian Road', location: 'Naguilian Road km 8', type: 'Landslide', severity: 'High', timeAgo: '30 mins ago', severityColor: Color(0xFFE53935), icon: Icons.warning_amber_rounded),
    RoadIncident(id: '5', title: 'Minor Accident – Bokawkan Road', location: 'Bokawkan Road, Baguio City', type: 'Accident', severity: 'Moderate', timeAgo: '1 hr ago', severityColor: Color(0xFFFFA726), icon: Icons.car_crash),
  ];
  static List<EmergencyService> emergencyServices = [
    EmergencyService(name: 'Baguio City Police Office', type: 'Police', address: 'Gov. Pack Road, Baguio City', phone: '(074) 442-0000', distance: '1.2 km', icon: Icons.local_police, color: Color(0xFF1565C0)),
    EmergencyService(name: 'Baguio General Hospital', type: 'Hospital', address: 'Gov. Pack Road, Baguio City', phone: '(074) 442-3780', distance: '1.5 km', icon: Icons.local_hospital, color: Color(0xFFE53935)),
    EmergencyService(name: 'Saint Louis University Hospital', type: 'Hospital', address: 'A. Bonifacio St., Baguio City', phone: '(074) 447-1736', distance: '0.8 km', icon: Icons.local_hospital, color: Color(0xFFE53935)),
    EmergencyService(name: 'Baguio City Fire Station', type: 'Fire Station', address: 'Magsaysay Ave, Baguio City', phone: '(074) 442-1688', distance: '1.0 km', icon: Icons.local_fire_department, color: Color(0xFFFF6F00)),
    EmergencyService(name: 'DOT Tourist Assistance Center', type: 'Tourist Assistance', address: 'Burnham Park, Baguio City', phone: '(074) 442-7014', distance: '1.2 km', icon: Icons.support_agent, color: Color(0xFF4CAF50)),
    EmergencyService(name: 'Baguio City CDRRMC', type: 'Disaster Response', address: 'City Hall, Baguio City', phone: '(074) 442-6222', distance: '1.8 km', icon: Icons.emergency, color: Color(0xFF9C27B0)),
  ];
}
