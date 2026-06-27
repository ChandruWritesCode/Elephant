import 'package:flutter/material.dart';

Widget chatCard({String? profileUrl}) {
  return Container(
    color: Colors.white,
    height: 80,
    width: double.infinity,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20),
            CircleAvatar(
              radius: 30,
              child: Icon(Icons.person), // use actual profile image here
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                spacing: 2,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sender name',
                        style: TextStyle(fontWeight: FontWeight(700)),
                      ),
                      Text('Time here'),
                    ],
                  ),
                  Text('Message overview'),
                ],
              ),
            ),
            SizedBox(width: 20),
          ],
        ),
        Divider(indent: 10, endIndent: 10),
      ],
    ),
  );
}
