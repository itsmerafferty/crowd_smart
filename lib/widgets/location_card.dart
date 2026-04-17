import 'package:flutter/material.dart';
import '../models/models.dart';

class LocationCard extends StatelessWidget {
  final TouristLocation location;
  final VoidCallback onTap;

  const LocationCard({super.key, required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Emoji Thumbnail
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      location.statusColor.withValues(alpha: 0.2),
                      location.statusColor.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(location.emoji,
                      style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Category
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            location.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            location.category,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Crowd status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: location.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.people,
                                  size: 12, color: location.statusColor),
                              const SizedBox(width: 3),
                              Text(
                                '${location.crowdStatus} Crowd',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: location.statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Color(0xFFFFA726)),
                            const SizedBox(width: 2),
                            Text(
                              location.rating.toString(),
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Travel time + distance
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 3),
                        Text(location.travelTime,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                        const SizedBox(width: 10),
                        const Icon(Icons.near_me,
                            size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 3),
                        Text(location.distance,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

