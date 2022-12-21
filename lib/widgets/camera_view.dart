import 'package:bluecherry_client/models/device.dart';
import 'package:flutter/material.dart';

class CameraView extends StatefulWidget {
  final Device device;

  const CameraView({Key? key, required this.device}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
