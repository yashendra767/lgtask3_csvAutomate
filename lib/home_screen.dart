import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'lg_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _pickedFileName;
  List<List<dynamic>> _csvData = [];
  bool _isLoading = false;

  Future<void> _pickCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();

      setState(() {
        _pickedFileName = result.files.single.name;
        _csvData = fields;
      });
    }
  }

  Future<void> _sendKML() async {
    if (_csvData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick a CSV file first.')));
      return;
    }

    setState(() => _isLoading = true);

    final lgService = LGService();
    bool connected = await lgService.connectToLG();

    if (connected) {
      String kml = lgService.generateKMLFromCSV(_csvData);

      await lgService.sendKMLToSlave(kml);

      await lgService.flyToCamera(_csvData);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KML Sent!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection Failed. Check Settings.')));
    }

    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
  }

  Future<void> _cleanKML() async {
    setState(() => _isLoading = true);

    await LGService().cleanKML();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('LG Cleaned!')));

    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CSV to 3D KML Automation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.file_present, size: 50, color: Colors.blue),
                  const SizedBox(height: 10),
                  Text(_pickedFileName ?? 'No CSV Selected', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickCSV,
                    child: const Text('Pick CSV File'),
                  ),
                ],
              ),
            ),

            const Spacer(),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: _sendKML,
                icon: const Icon(Icons.send),
                label: const Text('Send KML'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _cleanKML,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clean KML (Reset)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}