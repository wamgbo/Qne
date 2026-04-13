import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'qrScaner.dart';
import 'qrImage.dart';

// void main() => runApp(MaterialApp(home: Temp()));

class Temp extends StatelessWidget {
  int intval;
  String strval;
  Temp({super.key, required this.intval, required this.strval});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demo Home Page')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(this.intval.toString()),
          Text(this.strval),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, "go back");
            },
            child: const Text('go back'),
          ),
        ],
      ),
    );
  }
}
