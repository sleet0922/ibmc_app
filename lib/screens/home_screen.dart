import 'package:flutter/material.dart';
import '../services/redfish_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final RedfishService service;

  const HomeScreen({super.key, required this.service});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fanSpeedController = TextEditingController(text: '20');

  bool _isLoading = false;
  String _statusText = '';

  Future<void> _execute(Future<String> Function() action) async {
    setState(() => _isLoading = true);
    try {
      final result = await action();
      _setStatus(result);
    } catch (e) {
      _setStatus('操作失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setStatus(String text) {
    setState(() => _statusText = text);
  }

  Future<void> _logout() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _fanSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileWidth = (MediaQuery.of(context).size.width - 32 - 20) / 5;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_rounded, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            const Text('iBMC'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: _logout,
            tooltip: '退出登录',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            // ---- 操作按钮行 ----
            Row(
              children: [
                _tile('上电', Icons.power_settings_new_rounded, const Color(0xFF4CAF50), tileWidth, () => _execute(widget.service.powerOn)),
                const SizedBox(width: 5),
                _tile('下电', Icons.power_off_rounded, const Color(0xFFFF7043), tileWidth, () => _execute(widget.service.gracefulShutdown)),
                const SizedBox(width: 5),
                _tile('电源', Icons.info_outline_rounded, const Color(0xFF42A5F5), tileWidth, () => _execute(widget.service.getPowerStatus)),
                const SizedBox(width: 5),
                _tile('转速', Icons.air_rounded, const Color(0xFF26C6DA), tileWidth, () => _execute(widget.service.getFanInfo)),
                const SizedBox(width: 5),
                _tile('温度', Icons.thermostat_rounded, const Color(0xFF66BB6A), tileWidth, () => _execute(widget.service.getTemperatures)),
              ],
            ),

            const SizedBox(height: 8),

            // ---- 风扇调速行 ----
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fanSpeedController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: '风扇 %',
                      suffixText: '%',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () {
                            final speed = int.tryParse(_fanSpeedController.text.trim());
                            if (speed == null || speed < 0 || speed > 100) {
                              _setStatus('请输入 0-100 之间的转速百分比');
                              return;
                            }
                            _execute(() => widget.service.setFanSpeed(speed));
                          },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('设置', style: TextStyle(fontSize: 13)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ---- 快捷转速 ----
            _quickChips(),

            const SizedBox(height: 8),

            // ---- 终端 (填充剩余空间) ----
            Expanded(child: _terminal(theme)),
          ],
        ),
      ),
    );
  }

  Widget _tile(String label, IconData icon, Color color, double width, VoidCallback onTap) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: _isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickChips() {
    const speeds = [0, 20, 30, 50, 100];
    const labels = ['自动', '20%', '30%', '50%', '100%'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(speeds.length, (i) {
          final isActive = _fanSpeedController.text == speeds[i].toString();
          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: ActionChip(
              label: Text(labels[i], style: TextStyle(fontSize: 11, color: isActive ? Colors.black : null)),
              onPressed: _isLoading
                  ? null
                  : () {
                      _fanSpeedController.text = speeds[i].toString();
                      _execute(() => widget.service.setFanSpeed(speeds[i]));
                    },
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              backgroundColor: isActive ? const Color(0xFF64B5F6) : Colors.white.withValues(alpha: 0.03),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          );
        }),
      ),
    );
  }

  Widget _terminal(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _dot(const Color(0xFFFF5F57)),
              const SizedBox(width: 5),
              _dot(const Color(0xFFFFBD2E)),
              const SizedBox(width: 5),
              _dot(const Color(0xFF28CA41)),
              const Spacer(),
              if (_isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _statusText.isEmpty ? '\$ _' : _statusText,
                style: TextStyle(
                  color: _statusText.isEmpty ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFA5D6A7),
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}