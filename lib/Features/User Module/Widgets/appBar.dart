import 'package:flutter/material.dart';


// ignore: must_be_immutable
class AppBarContainer extends StatelessWidget {
   AppBarContainer( {super.key, required this.title,this.backArrow,});

  final String title;
   bool? backArrow=true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,

      child: Stack(
        children:[ 
          backArrow==true?IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back,
                size: 27,
                color: const Color.fromARGB(255, 92, 92, 92),
              ),
            ):Container(),

            Center(
              child: Text(
                
                title,
                
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
          //   Row(
          //    mainAxisAlignment: MainAxisAlignment.start,
          // crossAxisAlignment: CrossAxisAlignment.center,
          // children: [
          //   backArrow==true?IconButton(
          //     onPressed: () {
          //       Navigator.pop(context);
          //     },
          //     icon: Icon(
          //       Icons.arrow_back,
          //       size: 27,
          //       color: const Color.fromARGB(255, 92, 92, 92),
          //     ),
          //   ):Container(),
          //   backArrow==true? SizedBox(width: MediaQuery.of(context).size.width * 0.18):Container(),
          //   Text(
              
          //     title,
              
          //     style: TextStyle(
          //       color: Colors.black,
          //       fontSize: 20,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ],
        //),
        ]
      ),
    );
  }
}
