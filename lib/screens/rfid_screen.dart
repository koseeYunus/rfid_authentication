import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/rfid_bloc.dart';
import '../models/card_data.dart';
import '../services/serial_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RfidScreen extends StatelessWidget {
  RfidScreen({super.key});

  final SerialService _serialService = SerialService();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RfidBloc(),
      child: RfidView(serialService: _serialService),
    );
  }
}

class RfidView extends StatefulWidget {
  final SerialService serialService;

  const RfidView({
    super.key,
    required this.serialService,
  });

  @override
  _RfidViewState createState() => _RfidViewState();
}

class _RfidViewState extends State<RfidView> {
  String? _selectedPort;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _initPorts();
  }

  void _initPorts() {
    final ports = widget.serialService.getPorts();
    if (ports.isNotEmpty) {
      setState(() => _selectedPort = ports.first);
    }
  }

  Future<void> _connectToArduino() async {
    if (_selectedPort == null) {
      _showMessage('Lütfen bir port seçin');
      return;
    }

    setState(() => _isConnecting = true);

    try {
      await widget.serialService.connect(
        portName: _selectedPort!,
        onDataReceived: (data) {
          context.read<RfidBloc>().add(ProcessSerialData(data));
        },
      );
      _showMessage('Bağlantı başarılı');
    } catch (e) {
      _showMessage('Bağlantı hatası: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  void _disconnectFromArduino() {
    widget.serialService.disconnect();
    setState(() {});
    _showMessage('Bağlantı kapatıldı');
    context.read<RfidBloc>().add(ResetRfid());
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  @override
  void dispose() {
    widget.serialService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ports = widget.serialService.getPorts();
    final isConnected = widget.serialService.isConnected();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Kontrol Sistemi'),
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _disconnectFromArduino();
                _initPorts();
              },
              tooltip: 'Portları Yenile',
            ),
        ],
      ),
      body: Column(
        children: [
          _ConnectionPanel(
            ports: ports,
            selectedPort: _selectedPort,
            isConnected: isConnected,
            isConnecting: _isConnecting,
            onPortSelected: (value) => setState(() => _selectedPort = value),
            onConnect: _connectToArduino,
            onDisconnect: _disconnectFromArduino,
          ),
          const Divider(height: 1),
          const Expanded(
            child: _CardReaderContent(),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPanel extends StatelessWidget {
  final List<String> ports;
  final String? selectedPort;
  final bool isConnected;
  final bool isConnecting;
  final ValueChanged<String?> onPortSelected;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _ConnectionPanel({
    required this.ports,
    required this.selectedPort,
    required this.isConnected,
    required this.isConnecting,
    required this.onPortSelected,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bağlantı Durumu: ${isConnected ? 'Bağlı' : 'Bağlı Değil'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPort,
                    hint: const Text('Port Seçin'),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: ports.map((port) {
                      return DropdownMenuItem(
                        value: port,
                        child: Text(port),
                      );
                    }).toList(),
                    onChanged: isConnected ? null : onPortSelected,
                  ),
                ),
                const SizedBox(width: 16),
                if (!isConnected)
                  ElevatedButton(
                    onPressed: isConnecting ? null : onConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: isConnecting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Bağlan'),
                  )
                else
                  ElevatedButton(
                    onPressed: onDisconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Bağlantıyı Kapat'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardReaderContent extends StatelessWidget {
  const _CardReaderContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RfidBloc, RfidState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatusIcon(state),
                  if (state is RfidCardRead && state.cardData.serialNumbers.isNotEmpty)
                    _buildCardInfo(state.cardData),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(RfidState state) {
    if (state is RfidLoading) {
      return const CircularProgressIndicator();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(state).withOpacity(0.1),
      ),
      child: Icon(
        _getStatusIcon(state),
        size: 100,
        color: _getStatusColor(state),
      ),
    );
  }

  Color _getStatusColor(RfidState state) {
    if (state is RfidCardRead && state.cardData.isAuthorized) {
      return Colors.green;
    } else if (state is RfidCardRead && !state.cardData.isAuthorized) {
      return Colors.red;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon(RfidState state) {
    if (state is RfidCardRead && state.cardData.isAuthorized) {
      return Icons.check_circle;
    } else if (state is RfidCardRead && !state.cardData.isAuthorized) {
      return Icons.error;
    }
    return Icons.credit_card;
  }

  Widget _buildCardInfo(CardData cardData) {
    return Card(
      margin: const EdgeInsets.only(top: 20),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.credit_card, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Kart Seri Numarası:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cardData.serialNumbers.join(' '),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Son Okuma: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
