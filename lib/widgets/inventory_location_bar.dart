// lib/widgets/inventory_location_bar.dart
import 'package:flutter/material.dart';
import '../models/app_models.dart';

class InventoryLocationBar extends StatelessWidget {
  final StorageLocation selectedLocation;
  final ValueChanged<StorageLocation> onLocationChanged;

  const InventoryLocationBar({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: StorageLocation.values.length,
        itemBuilder: (context, index) {
          final loc = StorageLocation.values[index];
          final isSelected = loc == selectedLocation;
          
          return GestureDetector(
            onTap: () => onLocationChanged(loc),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF10C07B) : Colors.grey.shade600,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 3,
                      width: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10C07B), 
                        borderRadius: BorderRadius.circular(2)
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}