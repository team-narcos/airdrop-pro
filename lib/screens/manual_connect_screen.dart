import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/discovery/discovery_engine.dart';
import '../providers/transfer_provider.dart';
import '../core/design_system/ios18_theme.dart';

class ManualConnectScreen extends ConsumerStatefulWidget {
  const ManualConnectScreen({super.key});

  @override
  ConsumerState<ManualConnectScreen> createState() => _ManualConnectScreenState();
}

class _ManualConnectScreenState extends ConsumerState<ManualConnectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Peer Device');
  final _ipCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '37777');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final peer = PeerDevice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      platform: 'unknown',
      ipAddress: _ipCtrl.text.trim(),
      port: int.tryParse(_portCtrl.text.trim()),
      isTrusted: true,
    );
    ref.read(transferServiceProvider).addManualPeer(peer);
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Manual Connect')),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(iOS18Spacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter target device IP and port'),
                SizedBox(height: iOS18Spacing.lg),
                CupertinoTextFormFieldRow(
                  controller: _nameCtrl,
                  placeholder: 'Device name',
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                CupertinoTextFormFieldRow(
                  controller: _ipCtrl,
                  placeholder: 'IP address e.g. 192.168.1.20',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Required';
                    // very light validation
                    if (!RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(val)) return 'Invalid IP';
                    return null;
                  },
                ),
                CupertinoTextFormFieldRow(
                  controller: _portCtrl,
                  placeholder: 'Port (default 37777)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final p = int.tryParse((v ?? '').trim());
                    if (p == null || p <= 0 || p > 65535) return 'Invalid port';
                    return null;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
