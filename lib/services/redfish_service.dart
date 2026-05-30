import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';

class RedfishService {
  String _host = '';
  String _user = '';
  String _pass = '';
  String? _token;

  final HttpClient _client = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;

  Future<String> _sshExecute(String command) async {
    log('[iBMC] SSH 连接 $_host:22...');
    final socket = await SSHSocket.connect(_host, 22);
    final client = SSHClient(
      socket,
      username: _user,
      onPasswordRequest: () => _pass,
    );
    log('[iBMC] SSH 已连接，执行: $command');
    final result = await client.run(command);
    final output = utf8.decode(result);
    log('[iBMC] SSH 输出: $output');
    client.close();
    await socket.close();
    return output;
  }

  void setConnection(String host, String user, String pass) {
    _host = host;
    _user = user;
    _pass = pass;
    _token = null;
  }

  bool get isConnected => _token != null;

  Future<String> login() async {
    final uri = Uri.parse('https://$_host/redfish/v1/SessionService/Sessions');
    final body = jsonEncode({'UserName': _user, 'Password': _pass});

    final request = await _client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(body);

    final response = await request.close();
    final token = response.headers['x-auth-token']?.first;

    if (token == null || token.isEmpty) {
      final responseBody = await response.transform(utf8.decoder).join();
      throw Exception('登录失败，无法获取 Token。响应码: ${response.statusCode}\n$responseBody');
    }

    _token = token;
    return token;
  }

  Future<String> powerOn() async {
    _ensureConnected();
    return _postReset('On');
  }

  Future<String> gracefulShutdown() async {
    _ensureConnected();
    return _postReset('GracefulShutdown');
  }

  Future<String> getPowerStatus() async {
    _ensureConnected();
    final uri = Uri.parse('https://$_host/redfish/v1/Systems/1');
    final response = await _get(uri);
    final data = jsonDecode(response) as Map<String, dynamic>;
    final powerState = data['PowerState'] ?? 'Unknown';
    return '电源状态: $powerState';
  }

  Future<String> getPower() async {
    _ensureConnected();
    final uri = Uri.parse('https://$_host/redfish/v1/Chassis/1/Power');
    final response = await _get(uri);
    final data = jsonDecode(response) as Map<String, dynamic>;

    final controls = data['PowerControl'] as List<dynamic>?;
    if (controls == null || controls.isEmpty) {
      return '未找到功率数据';
    }

    final ctrl = controls[0] as Map<String, dynamic>;
    final current = ctrl['PowerConsumedWatts'];
    final metrics = ctrl['PowerMetrics'] as Map<String, dynamic>?;

    final sb = StringBuffer();
    if (current != null) sb.writeln('当前功率: $current W');
    if (metrics != null) {
      final min = metrics['MinConsumedWatts'];
      final max = metrics['MaxConsumedWatts'];
      final avg = metrics['AverageConsumedWatts'];
      if (min != null) sb.writeln('最低: $min W');
      if (max != null) sb.writeln('最高: $max W');
      if (avg != null) sb.writeln('平均: $avg W');
    }
    return sb.toString().trimRight();
  }

  Future<String> getFanInfo() async {
    _ensureConnected();
    final uri = Uri.parse('https://$_host/redfish/v1/Chassis/1/Thermal');
    final response = await _get(uri);
    final data = jsonDecode(response) as Map<String, dynamic>;

    final fans = data['Fans'] as List<dynamic>?;
    final oem = data['Oem']?['Huawei'] as Map<String, dynamic>?;

    final sb = StringBuffer();

    // 风扇模式 + 剩余时间
    if (oem != null) {
      final mode = oem['FanSpeedAdjustmentMode'] ?? 'Unknown';
      final speed = oem['FanSpeedLevelPercents'];
      final timeoutSec = oem['FanManualModeTimeoutSeconds'];
      sb.write('模式: $mode');
      if (speed != null) sb.write(' | 转速: $speed%');
      if (timeoutSec != null && timeoutSec is num) {
        final hours = timeoutSec / 3600;
        sb.write(' | 保持剩余: ${hours.toStringAsFixed(1)} 小时');
      }
      sb.writeln();
      sb.writeln();
    }

    if (fans == null || fans.isEmpty) {
      sb.writeln('未找到风扇数据');
      return sb.toString();
    }

    for (final fan in fans) {
      final f = fan as Map<String, dynamic>;
      final name = f['Name'] ?? f['MemberId'] ?? '?';
      final reading = f['Reading'] ?? 'N/A';
      final unit = f['ReadingUnits'] ?? '';
      sb.writeln('$name: $reading $unit');
    }
    return sb.toString();
  }

  static const _tempNameMap = {
    'Inlet Temp': '进风口',
    'Outlet Temp': '出风口',
    'CPU1 Temp': 'CPU1',
    'CPU2 Temp': 'CPU2',
    'CPU1 Core Rem': 'CPU1核心',
    'CPU2 Core Rem': 'CPU2核心',
    'CPU1 DTS': 'CPU1 DTS传感器',
    'CPU2 DTS': 'CPU2 DTS传感器',
    'DTS Temp': 'DTS传感器',
    'DTS': 'DTS传感器',
    'PCH Temp': 'PCH芯片',
    'DIMM Temp': '内存',
    'DIMM Area Temp': '内存区域',
    'MEM Temp': '内存',
    'MEM': '内存',
    'VDDQ Temp': '内存VDDQ',
    'VDDQ': '内存VDDQ',
    'VRD Temp': 'VRD供电',
    'VRD': 'VRD供电',
    'RAID Temp': 'RAID卡',
    'SSD Temp': '固态硬盘',
    'Disk Temp': '硬盘',
    'HDD Temp': '机械硬盘',
    'BMC Temp': 'BMC管理芯片',
    'Ambient Temp': '环境温度',
    'NIC Temp': '网卡',
    'Rear Disk Temp': '后置硬盘',
    'RearDisk Temp': '后置硬盘',
    'REARDISK': '后置硬盘',
  };

  String _translateTempName(String rawName) {
    // 1. 精确匹配
    if (_tempNameMap.containsKey(rawName)) return _tempNameMap[rawName]!;
    // 2. 去掉尾部 " Temp" 再匹配
    if (rawName.endsWith(' Temp')) {
      final stem = rawName.substring(0, rawName.length - 5);
      if (_tempNameMap.containsKey(stem)) return _tempNameMap[stem]!;
    }
    // 3. 子串模糊匹配 (大小写不敏感)
    final lower = rawName.toLowerCase();
    for (final entry in _tempNameMap.entries) {
      if (lower.contains(entry.key.toLowerCase()) || entry.key.toLowerCase().contains(lower)) {
        return entry.value;
      }
    }
    return rawName;
  }

  Future<String> getTemperatures() async {
    _ensureConnected();
    final uri = Uri.parse('https://$_host/redfish/v1/Chassis/1/Thermal');
    final response = await _get(uri);
    final data = jsonDecode(response) as Map<String, dynamic>;

    final temps = data['Temperatures'] as List<dynamic>?;
    if (temps == null || temps.isEmpty) {
      return '未找到温度传感器数据';
    }

    final sb = StringBuffer();
    for (final t in temps) {
      final temp = t as Map<String, dynamic>;
      final rawName = temp['Name'] as String? ?? temp['MemberId'] ?? '?';
      final name = _translateTempName(rawName);
      final reading = temp['ReadingCelsius'];

      final icon = reading == null ? '⬜'
          : (temp['UpperThresholdCritical'] != null && reading >= (temp['UpperThresholdCritical'] as num))
              ? '🔴'
              : (temp['UpperThresholdNonCritical'] != null && reading >= (temp['UpperThresholdNonCritical'] as num))
                  ? '🟡'
                  : '🟢';

      sb.writeln('$icon $name: ${reading ?? "N/A"}°C');
    }

    return sb.toString();
  }

  Future<String> setFanSpeed(int percent, {int timeoutSeconds = 4294967295}) async {
    log('[iBMC] ===== 开始设置风扇转速: $percent%, timeout: $timeoutSeconds =====');

    try {
      log('[iBMC] 尝试 SSH 直连 iBMC...');
      if (percent == 0) {
        final output = await _sshExecute('ipmcset -d fanmode -v 0');
        return 'SSH: 已切换为自动模式\n$output';
      } else {
        final levelOutput = await _sshExecute('ipmcset -d fanlevel -v $percent');
        final modeOutput = await _sshExecute('ipmcset -d fanmode -v 1 0');
        return 'SSH: 已设置手动 $percent% (永久)\n$levelOutput\n$modeOutput';
      }
    } catch (e) {
      log('[iBMC] SSH 失败，回退到 Redfish API: $e');
    }

    _ensureConnected();
    log('[iBMC] 回退到 Redfish API...');

    final uri = Uri.parse('https://$_host/redfish/v1/Chassis/1/Thermal');

    log('[iBMC] 步骤1: GET 获取 ETag...');
    final getRequest = await _client.getUrl(uri);
    getRequest.headers.set('X-Auth-Token', _token!);
    final getResponse = await getRequest.close();
    final etag = getResponse.headers['etag']?.first;
    log('[iBMC] GET 状态码: ${getResponse.statusCode}, ETag: $etag');

    String body;
    String mode;
    if (percent == 0) {
      body = jsonEncode({
        'Oem': {
          'Huawei': {
            'FanSpeedAdjustmentMode': 'Automatic',
          },
        },
      });
      mode = '自动';
    } else {
      body = jsonEncode({
        'Oem': {
          'Huawei': {
            'FanSpeedAdjustmentMode': 'Manual',
            'FanSpeedLevelPercents': percent,
            'FanManualModeTimeoutSeconds': timeoutSeconds,
          },
        },
      });
      mode = '手动 $percent%';
    }
    log('[iBMC] 请求体: $body');

    for (int attempt = 0; attempt < 3; attempt++) {
      log('[iBMC] 第 ${attempt + 1} 次尝试 PATCH 请求...');
      try {
        final request = await _client.openUrl('PATCH', uri);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Auth-Token', _token!);
        if (etag != null && etag.isNotEmpty) {
          request.headers.set('If-Match', etag);
          log('[iBMC] 带上 If-Match: $etag');
        }
        request.write(body);

        final response = await request.close();
        final statusCode = response.statusCode;
        final responseBody = await response.transform(utf8.decoder).join();
        log('[iBMC] 响应状态码: $statusCode');
        log('[iBMC] 响应体: "$responseBody"');

        if (statusCode == 200 || statusCode == 204) {
          log('[iBMC] 风扇设置成功!');
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          final actualTimeout = data['Oem']?['Huawei']?['FanManualModeTimeoutSeconds'];
          if (actualTimeout != null) {
            return '风扇已切换为 $mode模式，实际超时: ${actualTimeout}s';
          }
          return '风扇已切换为 $mode模式';
        }
        if (statusCode == 412) {
          log('[iBMC] 收到412, 第 ${attempt + 1} 次失败');
          if (attempt < 2) {
            log('[iBMC] 等待500ms后重试...');
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          return '设置风扇转速失败(412)，ETag 不匹配，请重试';
        }
        log('[iBMC] 未知状态码, 抛出异常');
        throw Exception('设置风扇转速失败。响应码: $statusCode\n$responseBody');
      } on HttpException catch (e) {
        log('[iBMC] HttpException: ${e.message}');
        if (attempt < 2) {
          log('[iBMC] 等待800ms后重试...');
          await Future.delayed(const Duration(milliseconds: 800));
          continue;
        }
        return '设置风扇转速失败：服务器连接中断，请重试';
      }
    }

    log('[iBMC] 所有重试均失败');
    return '设置风扇转速失败，请稍后重试';
  }

  void _ensureConnected() {
    if (_token == null) {
      throw Exception('请先连接服务器');
    }
  }

  Future<String> _postReset(String resetType) async {
    final uri = Uri.parse(
      'https://$_host/redfish/v1/Systems/1/Actions/ComputerSystem.Reset',
    );
    final body = jsonEncode({'ResetType': resetType});

    final request = await _client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('X-Auth-Token', _token!);
    request.write(body);

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200 || response.statusCode == 204) {
      final action = resetType == 'On' ? '上电' : '优雅关机';
      return '$action 指令已发送成功';
    }
    throw Exception('操作失败。响应码: ${response.statusCode}\n$responseBody');
  }

  Future<String> _get(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.set('X-Auth-Token', _token!);

    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception('请求失败。响应码: ${response.statusCode}');
    }
    return response.transform(utf8.decoder).join();
  }

  void dispose() {
    _client.close();
  }
}