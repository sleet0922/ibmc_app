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
      if (mounted) setState(() => _isLoading = false);
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

  // ---------- 操作卡片数据结构 ----------
  static const _allActions = [
    _ActionItem('上电', Icons.power_settings_new_rounded, Color(0xFF66BB6A)),
    _ActionItem('下电', Icons.power_off_rounded, Color(0xFFFF7043)),
    _ActionItem('电源状态', Icons.info_outline_rounded, Color(0xFF42A5F5)),
    _ActionItem('风扇', Icons.air_rounded, Color(0xFF26C6DA)),
    _ActionItem('温度', Icons.thermostat_rounded, Color(0xFFEF5350)),
    _ActionItem('功率', Icons.bolt_rounded, Color(0xFFFFCA28)),
  ];

  Future<void> _onAction(String label) async {
    switch (label) {
      case '上电':
        await _execute(widget.service.powerOn);
      case '下电':
        await _execute(widget.service.gracefulShutdown);
      case '电源状态':
        await _execute(widget.service.getPowerStatus);
      case '风扇':
        await _execute(widget.service.getFanInfo);
      case '温度':
        await _execute(widget.service.getTemperatures);
      case '功率':
        await _execute(widget.service.getPower);
    }
  }

  void _setFanAndApply(int speed) {
    _fanSpeedController.text = speed.toString();
    _execute(() => widget.service.setFanSpeed(speed));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.dns_rounded, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('iBMC'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, size: 22),
            onPressed: _logout,
            tooltip: '退出登录',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ---- 操作卡片组 ----
          _sectionLabel('服务器操作'),
          const SizedBox(height: 8),
          _actionCard(theme, _allActions),

          const SizedBox(height: 20),

          // ---- 风扇控制卡片 ----
          _sectionLabel('风扇控制'),
          const SizedBox(height: 8),
          _fanControlCard(theme),

          const SizedBox(height: 8),

          // ---- 快捷转速 ----
          _quickChips(theme),

          const SizedBox(height: 20),

          // ---- 终端输出卡片 ----
          _sectionLabel('输出'),
          const SizedBox(height: 8),
          _terminalCard(theme),
        ],
      ),
    );
  }

  // ---------- 区块标题 ----------
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  // ---------- 操作卡片 ----------
  Widget _actionCard(ThemeData theme, List<_ActionItem> items) {
    // 每行3个，自动换行
    const perRow = 3;
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += perRow) {
      final chunk = items.skip(i).take(perRow).toList();
      rows.add(
        Row(
          children: chunk.map((item) {
            return Expanded(
              child: _actionTile(theme, item),
            );
          }).toList(),
        ),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: rows,
        ),
      ),
    );
  }

  Widget _actionTile(ThemeData theme, _ActionItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _isLoading ? null : () => _onAction(item.label),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 风扇控制卡片 ----------
  Widget _fanControlCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // 图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF26C6DA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.air_rounded, color: Color(0xFF26C6DA), size: 24),
            ),
            const SizedBox(width: 16),

            // 输入框
            Expanded(
              child: TextField(
                controller: _fanSpeedController,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  labelText: '转速百分比',
                  suffixText: '%',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 设置按钮
            SizedBox(
              height: 48,
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
                  minimumSize: const Size(80, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 快捷芯片 ----------
  Widget _quickChips(ThemeData theme) {
    const speeds = [0, 20, 30, 50, 100];
    const labels = ['自动', '20%', '30%', '50%', '100%'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: List.generate(speeds.length, (i) {
          final isActive = _fanSpeedController.text == speeds[i].toString();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              selected: isActive,
              onSelected: _isLoading ? null : (_) => _setFanAndApply(speeds[i]),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
              checkmarkColor: theme.colorScheme.primary,
              side: BorderSide(
                color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.5) : theme.colorScheme.outline,
              ),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------- 终端卡片 ----------
  Widget _terminalCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 窗口装饰点 + 加载
              Row(
                children: [
                  _dot(const Color(0xFFFF5F57)),
                  const SizedBox(width: 6),
                  _dot(const Color(0xFFFFBD2E)),
                  const SizedBox(width: 6),
                  _dot(const Color(0xFF28CA41)),
                  const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _statusText.isEmpty ? '\$ _' : _statusText,
                    style: TextStyle(
                      color: _statusText.isEmpty
                          ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
                          : const Color(0xFF81C784),
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ---------- 辅助数据类 ----------
class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionItem(this.label, this.icon, this.color);
}