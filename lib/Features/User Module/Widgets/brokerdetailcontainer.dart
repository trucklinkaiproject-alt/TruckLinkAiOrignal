import 'package:flutter/material.dart';
import 'package:trucklinkai_orignal/Core/Constants/appColors.dart';

class Brokerdetailcontainer extends StatelessWidget {
  const Brokerdetailcontainer({
    super.key,
    required this.name,
    required this.Location,
    required this.rating,
    required this.reviews,
    required this.estTime,
    this.ontap,
    required this.brokerUid,
  });
  final String name;
  final String Location;
  final String rating;
  final String reviews;
  final String estTime;
  final VoidCallback? ontap;
  final String brokerUid;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: ontap,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10, left: 20, right: 20),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Appcolors.primaryBlue,
            child: Text(
              name[0],
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            name,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 15),
                  SizedBox(width: 5),
                  Text(
                    "$rating/5",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  Text(
                    "($reviews reviews)",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: const Color.fromARGB(255, 6, 6, 6),
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    Location,
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Est Time ",
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
              Text(estTime, style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
