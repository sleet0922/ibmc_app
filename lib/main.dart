import 'package:flutter/material.dart';
import 'services/redfish_service.dart';

void main() {
  runApp(const IBMCApp());
}

class IBMCApp extends StatelessWidget {
  const IBMCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iBMC 管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RedfishService _service = RedfishService();

  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _fanSpeedController = TextEditingController(text: '20');

  bool _isLoading = false;
  bool _isConnected = false;
  String _statusText = '';
  bool _obscurePass = true;

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    _fanSpeedController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      _setStatus('请填写 IP、用户名和密码');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _service.setConnection(host, user, pass);
      final token = await _service.login();
      setState(() {
        _isConnected = true;
        _statusText = '连接成功！Token: ${token.substring(0, token.length > 16 ? 16 : token.length)}...';
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusText = '连接失败: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iBMC 服务器管理'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionCard(),
            const SizedBox(height: 16),
            if (_isConnected) ...[
              _buildControlCard(),
              const SizedBox(height: 16),
            ],
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.dns, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('服务器连接', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_isConnected)
                  Chip(
                    label: const Text('已连接'),
                    backgroundColor: Colors.green.shade800,
                    avatar: const Icon(Icons.check_circle, size: 18, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'IP 地址',
                hintText: '192.168.3.100',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: '用户名',
                hintText: 'root',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passController,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: '密码',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _connect,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.link),
              label: Text(_isConnected ? '重新连接' : '连接服务器'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('服务器控制', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.power_settings_new,
                  label: '上电',
                  color: Colors.green,
                  onTap: () => _execute(_service.powerOn),
                ),
                _buildActionButton(
                  icon: Icons.power_off,
                  label: '优雅关机',
                  color: Colors.orange,
                  onTap: () => _execute(_service.gracefulShutdown),
                ),
                _buildActionButton(
                  icon: Icons.info_outline,
                  label: '电源状态',
                  color: Colors.blue,
                  onTap: () => _execute(_service.getPowerStatus),
                ),
                _buildActionButton(
                  icon: Icons.toys,
                  label: '风扇信息',
                  color: Colors.cyan,
                  onTap: () => _execute(_service.getFanInfo),
                ),
                _buildActionButton(
                  icon: Icons.data_object,
                  label: 'Thermal原始数据',
                  color: Colors.purple,
                  onTap: () => _execute(_service.getRawThermal),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('风扇调速', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fanSpeedController,
                    decoration: const InputDecoration(
                      labelText: '转速百分比',
                      suffixText: '%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          final speed = int.tryParse(_fanSpeedController.text.trim());
                          if (speed == null || speed < 0 || speed > 100) {
                            _setStatus('请输入 0-100 之间的转速百分比');
                            return;
                          }
                          _execute(() => _service.setFanSpeed(speed));
                        },
                  icon: const Icon(Icons.send),
                  label: const Text('设置'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 64) / 2,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.terminal, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('执行结果', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minHeight: 80, maxHeight: 300),
              child: SingleChildScrollView(
                child: SelectableText(
                  _statusText.isEmpty ? '等待操作...' : _statusText,
                  style: const TextStyle(
                    color: Colors.lightGreenAccent,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}