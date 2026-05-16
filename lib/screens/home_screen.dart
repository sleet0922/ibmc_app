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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('iBMC'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: '退出登录',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader('服务器控制', Icons.tune_rounded),
            const SizedBox(height: 10),
            _buildPowerGrid(),
            const SizedBox(height: 20),
            _buildSectionHeader('风扇调速', Icons.speed_rounded),
            const SizedBox(height: 10),
            _buildFanCard(),
            const SizedBox(height: 20),
            _buildSectionHeader('执行结果', Icons.terminal_rounded),
            const SizedBox(height: 10),
            _buildTerminal(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPowerGrid() {
    return Row(
      children: [
        Expanded(child: _buildPowerTile('上电', Icons.power_settings_new_rounded, const Color(0xFF4CAF50), () => _execute(widget.service.powerOn))),
        const SizedBox(width: 10),
        Expanded(child: _buildPowerTile('下电', Icons.power_off_rounded, const Color(0xFFFF7043), () => _execute(widget.service.gracefulShutdown))),
        const SizedBox(width: 10),
        Expanded(child: _buildPowerTile('状态', Icons.info_outline_rounded, const Color(0xFF42A5F5), () => _execute(widget.service.getPowerStatus))),
        const SizedBox(width: 10),
        Expanded(child: _buildPowerTile('风扇', Icons.air_rounded, const Color(0xFF26C6DA), () => _execute(widget.service.getFanInfo))),
      ],
    );
  }

  Widget _buildPowerTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFanCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fanSpeedController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '转速百分比',
                    suffixText: '%',
                    prefixIcon: Icon(Icons.speed_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
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
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('设置'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(100, 52),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildQuickSpeedRow(),
        ],
      ),
    );
  }

  Widget _buildQuickSpeedRow() {
    final speeds = [0, 10, 20, 30, 50, 100];
    final labels = ['自动', '10%', '20%', '30%', '50%', '100%'];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(speeds.length, (i) {
        return ActionChip(
          label: Text(labels[i], style: const TextStyle(fontSize: 12)),
          onPressed: _isLoading
              ? null
              : () {
                  _fanSpeedController.text = speeds[i].toString();
                  _execute(() => widget.service.setFanSpeed(speeds[i]));
                },
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          backgroundColor: Colors.white.withValues(alpha: 0.03),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }),
    );
  }

  Widget _buildTerminal() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _terminalDot(const Color(0xFFFF5F57)),
              const SizedBox(width: 6),
              _terminalDot(const Color(0xFFFFBD2E)),
              const SizedBox(width: 6),
              _terminalDot(const Color(0xFF28CA41)),
              const Spacer(),
              if (_isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                _statusText.isEmpty ? '\$ _' : _statusText,
                style: TextStyle(
                  color: _statusText.isEmpty
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFA5D6A7),
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _terminalDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}