// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

class RedfishService {
  String _host = '';
  String _user = '';
  String _pass = '';
  String? _token;

  final HttpClient _client = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;

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

  Future<String> getFanInfo() async {
    _ensureConnected();
    final uri = Uri.parse('https://$_host/redfish/v1/Chassis/1/Thermal');
    final response = await _get(uri);
    final data = jsonDecode(response) as Map<String, dynamic>;

    final fans = data['Fans'] as List<dynamic>?;
    if (fans == null || fans.isEmpty) {
      return '未找到风扇信息';
    }

    final sb = StringBuffer();
    sb.writeln('=== 风扇信息 ===');
    for (final fan in fans) {
      final f = fan as Map<String, dynamic>;
      final name = f['Name'] ?? f['MemberId'] ?? 'Unknown';
      final reading = f['Reading'] ?? 'N/A';
      final unit = f['ReadingUnits'] ?? '';
      final status = f['Status']?['State'] ?? 'N/A';
      sb.writeln('$name: $reading $unit (状态: $status)');
    }
    return sb.toString();
  }

  Future<String> getRawThermal() async {
    _ensureConnected();
    final uri = Uri.parse('https://$_host/redfish/v1/Chassis/1/Thermal');
    final response = await _get(uri);
    final data = jsonDecode(response) as Map<String, dynamic>;
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  Future<String> setFanSpeed(int percent) async {
    _ensureConnected();
    print('[iBMC] ===== 开始设置风扇转速: $percent% =====');

    final uri = Uri.parse('https://$_host/redfish/v1/Chassis/1/Thermal');

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
            'FanManualModeTimeoutSeconds': 0,
          },
        },
      });
      mode = '手动 $percent%';
    }
    print('[iBMC] 请求体: $body');

    for (int attempt = 0; attempt < 3; attempt++) {
      print('[iBMC] 第 ${attempt + 1} 次尝试 PATCH 请求...');
      try {
        final request = await _client.openUrl('PATCH', uri);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Auth-Token', _token!);
        request.write(body);

        final response = await request.close();
        final statusCode = response.statusCode;
        final responseBody = await response.transform(utf8.decoder).join();
        print('[iBMC] 响应状态码: $statusCode');
        print('[iBMC] 响应体: "$responseBody"');

        if (statusCode == 200 || statusCode == 204) {
          print('[iBMC] 风扇设置成功!');
          return '风扇已切换为 $mode模式';
        }
        if (statusCode == 412) {
          print('[iBMC] 收到412, 第 ${attempt + 1} 次失败');
          if (attempt < 2) {
            print('[iBMC] 等待500ms后重试...');
            await Future.delayed(const Duration(milliseconds: 500));
            continue;
          }
          return '设置风扇转速失败(412)，请确认服务器已完全启动(进入系统)后重试';
        }
        print('[iBMC] 未知状态码, 抛出异常');
        throw Exception('设置风扇转速失败。响应码: $statusCode\n$responseBody');
      } on HttpException catch (e) {
        print('[iBMC] HttpException: ${e.message}');
        if (attempt < 2) {
          print('[iBMC] 等待800ms后重试...');
          await Future.delayed(const Duration(milliseconds: 800));
          continue;
        }
        return '设置风扇转速失败：服务器连接中断，请确认服务器已完全启动(进入系统)后重试';
      }
    }

    print('[iBMC] 所有重试均失败');
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
}