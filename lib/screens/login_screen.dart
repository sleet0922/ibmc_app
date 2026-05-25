import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/redfish_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _service = RedfishService();
  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _hostFocus = FocusNode();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hostController.text = prefs.getString('ibmc_host') ?? '';
      _userController.text = prefs.getString('ibmc_user') ?? '';
      _passController.text = prefs.getString('ibmc_pass') ?? '';
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ibmc_host', _hostController.text.trim());
    await prefs.setString('ibmc_user', _userController.text.trim());
    await prefs.setString('ibmc_pass', _passController.text);
  }

  Future<void> _login() async {
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text;

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() => _errorText = '请填写 IP、用户名和密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      _service.setConnection(host, user, pass);
      await _service.login();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(service: _service)),
        );
      }
    } catch (e) {
      setState(() => _errorText = '登录失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAndSave() async {
    await _saveCredentials();
    await _login();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    _hostFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo 区域
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.dns_rounded,
                        size: 36,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 标题
                  Text(
                    'iBMC',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '服务器管理控制台',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // 输入框组 — 用 Column 间距替代 SizedBox
                  TextField(
                    controller: _hostController,
                    focusNode: _hostFocus,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _userFocus.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: 'IP 地址',
                      hintText: '192.168.3.100',
                      prefixIcon: Icon(Icons.language_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _userController,
                    focusNode: _userFocus,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passFocus.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: '用户名',
                      hintText: 'Administrator',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passController,
                    focusNode: _passFocus,
                    obscureText: _obscurePass,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _loginAndSave(),
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                  ),

                  // 错误提示
                  if (_errorText != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorText!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // 主按钮
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _loginAndSave,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login_rounded, size: 20),
                    label: Text(_isLoading ? '连接中...' : '保存并登录'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _login,
                    icon: const Icon(Icons.wifi_find_rounded, size: 20),
                    label: const Text('仅登录'),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}