import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lg_service.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _isTesting = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _rigsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('lg_ip') ?? '';
      _usernameController.text = prefs.getString('lg_username') ?? 'lg';
      _passwordController.text = prefs.getString('lg_password') ?? 'lq';
      _portController.text = (prefs.getInt('lg_port') ?? 22).toString();
      _rigsController.text = (prefs.getInt('lg_rigs') ?? 3).toString();
    });
  }

  Future<void> _testConnection() async {
    setState(() => _isTesting = true);

    await _saveSettings();
    final lgService = LGService();
    bool isConnected = await lgService.connectToLG();

    if (mounted) {
      setState(() => _isTesting = false);
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Connection Successful!'),
                backgroundColor: Colors.green
            )
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Connection Failed! Check IP/User/Pass.'),
                backgroundColor: Colors.red
            )
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lg_ip', _ipController.text);
      await prefs.setString('lg_username', _usernameController.text);
      await prefs.setString('lg_password', _passwordController.text);
      await prefs.setInt('lg_port', int.parse(_portController.text));
      await prefs.setInt('lg_rigs', int.parse(_rigsController.text));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection settings saved!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LG Connection Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(labelText: 'IP Address', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Enter IP' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(labelText: 'Port', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _rigsController,
                      decoration: const InputDecoration(labelText: 'Rigs', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.network_check),
                label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50)
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Save Connection'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}