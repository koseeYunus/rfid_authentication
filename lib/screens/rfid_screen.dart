import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/rfid_bloc.dart';
import '../models/card_data.dart';
import '../models/port_info.dart';
import '../services/serial_service.dart';


/// RFID ekranını oluşturan ana widget
class RfidScreen extends StatelessWidget {
  RfidScreen({super.key});

  final SerialService _serialService = SerialService();

  // Kullanılacak servis tipine göre değiştirilebilir
  // final serialService = ArduinoSerialService();  // Arduino için
  //final serialService = OSDPSerialService();     // OSDP okuyucu için

  /*
   @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RfidBloc(serialService: serialService)
        ..add(LoadPorts()),
      child: const RfidView(),
    );
  }
}
   */

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RfidBloc(serialService: _serialService)
        ..add(LoadPorts()),
      child: const RfidView(),
    );
  }
}

class RfidView extends StatelessWidget {
  const RfidView({super.key});

  void _showPortSelectionDialog(BuildContext context, RfidPortsLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final bloc = context.read<RfidBloc>();
        return PortSelectionDialog(
          ports: state.ports,
          selectedPort: state.selectedPort,
          onPortSelected: (port) {
            if (port != null) {
              bloc.add(SelectPort(port)); // Bloc'u dışarıdan kullan
            }
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID Kontrol Sistemi'),
        actions: [
          BlocBuilder<RfidBloc, RfidState>(
            buildWhen: (previous, current) =>
            current is RfidConnected ||
                (previous is RfidConnected && current is! RfidConnected),
            builder: (context, state) {
              if (state is RfidConnected) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    context.read<RfidBloc>().add(DisconnectPort());
                    context.read<RfidBloc>().add(LoadPorts());
                  },
                  tooltip: 'Portları Yenile',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocListener<RfidBloc, RfidState>(
        listener: (context, state) {
          if (state is RfidError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Column(
          children: [
            BlocBuilder<RfidBloc, RfidState>(
              buildWhen: (previous, current) =>
              current is BasePortState,
              builder: (context, state) {
                if (state is BasePortState) {  // BasePortState kullan
                  return _ConnectionPanel(
                    selectedPort: state.selectedPort,
                    isConnected: state is RfidConnected,
                    isConnecting: state is RfidConnecting,
                    onPortSelectionRequest: () {
                      if (state is RfidPortsLoaded) {
                        _showPortSelectionDialog(context, state);
                      }
                    },
                    onConnect: () => context.read<RfidBloc>().add(ConnectToPort()),
                    onDisconnect: () => context.read<RfidBloc>().add(DisconnectPort()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<RfidBloc, RfidState>(
                buildWhen: (previous, current) {
                  // BasePortState durumlarında kart bilgisi değiştiğinde rebuild et
                  if (previous is BasePortState && current is BasePortState) {
                    return previous.lastCardRead != current.lastCardRead;
                  }
                  // veya hata/başlangıç durumlarında
                  return current is RfidInitial || current is RfidError;
                },
                builder: (context, state) {
                  return _CardReaderContent(state: state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Bağlantı panelini oluşturan widget
class _ConnectionPanel extends StatelessWidget {
  /// Seçili port bilgisi
  final PortInfo? selectedPort;

  /// Bağlantı durumu
  final bool isConnected;

  /// Bağlanma işlemi devam ediyor mu?
  final bool isConnecting;

  /// Port seçimi için callback
  final VoidCallback onPortSelectionRequest;

  /// Bağlanma işlemi için callback
  final VoidCallback onConnect;

  /// Bağlantıyı kesme işlemi için callback
  final VoidCallback onDisconnect;

  const _ConnectionPanel({
    required this.selectedPort,
    required this.isConnected,
    required this.isConnecting,
    required this.onPortSelectionRequest,
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
            // Bağlantı durumu göstergesi
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
                // Port seçim butonu
                Expanded(
                  child: OutlinedButton(
                    onPressed: isConnected ? null : onPortSelectionRequest,
                    child: Text(
                      selectedPort?.toString() ?? 'Port Seçin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Bağlan/Bağlantıyı Kes butonu
                if (!isConnected)
                  ElevatedButton(
                    onPressed: isConnecting ? null : onConnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Bağlantıyı Kes'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kart okuyucu içeriğini gösteren widget
class _CardReaderContent extends StatelessWidget {
  final RfidState state;

  const _CardReaderContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(),
              if (state is BasePortState &&
                  (state as BasePortState).lastCardRead != null &&
                  (state as BasePortState).lastCardRead!.serialNumbers.isNotEmpty)
                _buildCardInfo((state as BasePortState).lastCardRead!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (state is RfidConnecting) {
      return const CircularProgressIndicator();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor().withOpacity(0.1),
      ),
      child: Icon(
        _getStatusIcon(),
        size: 100,
        color: _getStatusColor(),
      ),
    );
  }

  Color _getStatusColor() {
    if (state is BasePortState && (state as BasePortState).lastCardRead != null) {
      final lastCard = (state as BasePortState).lastCardRead!;
      return lastCard.isAuthorized ? Colors.green : Colors.red;
    } else if (state is RfidConnected) {
      return Colors.blue;
    } else if (state is RfidError) {
      return Colors.red;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (state is BasePortState && (state as BasePortState).lastCardRead != null) {
      final lastCard = (state as BasePortState).lastCardRead!;
      return lastCard.isAuthorized ? Icons.check_circle : Icons.error;
    } else if (state is RfidConnected) {
      return Icons.usb;
    } else if (state is RfidError) {
      return Icons.error_outline;
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
            if (cardData.message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                cardData.message,
                style: TextStyle(
                  color: cardData.isAuthorized ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


/// Port seçim dialogunu oluşturan widget
class PortSelectionDialog extends StatelessWidget {
  final List<PortInfo> ports;
  final PortInfo? selectedPort;
  final ValueChanged<PortInfo?> onPortSelected;

  const PortSelectionDialog({
    Key? key,
    required this.ports,
    this.selectedPort,
    required this.onPortSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Ekranın %80'i kadar yükseklik
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Port Seçimi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ports.map((port) => _buildPortItem(context, port)).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortItem(BuildContext context, PortInfo port) {
    final isSelected = selectedPort?.name == port.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          onPortSelected(port);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.usb,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      port.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Port durumu için indikatör
                  Icon(
                    port.isOpen ? Icons.link : Icons.link_off,
                    size: 16,
                    color: port.isOpen ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DefaultTextStyle(
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: port.getDetailedInfo()
                      .split('\n')
                      .map((line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line),
                  ))
                      .toList(),
                ),
              ),
              if (port.additionalInfo.isNotEmpty) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  title: const Text(
                    'Detaylı Bilgiler',
                    style: TextStyle(fontSize: 14),
                  ),
                  children: port.additionalInfo.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
}
