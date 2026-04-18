import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var channel = const MethodChannel('uniqueChannelName');
  Future<void> callNativeCode() async {
    try{
      await channel.invokeMethod('userName');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Code'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MaterialButton(
              color: Colors.teal,
              textColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              onPressed: callNativeCode,
              child: const Text('Click Me')
            )
          ],
        ),
      ),
    );
  }
}
