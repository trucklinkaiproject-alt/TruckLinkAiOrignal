import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class LocationContainer extends StatelessWidget {
  const LocationContainer({
    super.key,
    this.onTap,
    required this.city,
    required this.address,
    required this.clr,
  });
  final VoidCallback? onTap;
  final String city;
  final String address;
  final Color clr;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_on, color: clr, size: 33),
            SizedBox(width: 10),
            SizedBox(width: 10),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    address,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            Icon(Icons.edit, color: clr, size: 25),
          ],
        ),
      ),
    );
  }
}
