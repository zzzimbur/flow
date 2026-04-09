import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class YooKassaService {
  // Получаем данные из .env
  static String get _shopId {
    return dotenv.env['YOOKASSA_SHOP_ID'] ?? '';
  }

  static String get _secretKey {
    return dotenv.env['YOOKASSA_SECRET_KEY'] ?? '';
  }

  static String get _returnUrl => 
      dotenv.env['YOOKASSA_RETURN_URL'] ?? 'flowapp://payment-success';

  static String get _mode => 
      dotenv.env['YOOKASSA_MODE'] ?? 'test';

  static const String _apiUrl = 'https://api.yookassa.ru/v3';
  static const String subscriptionPrice = '299.00';
  static const String currency = 'RUB';
  
  final _uuid = const Uuid();

  // Проверка что ЮКасса настроена
  bool get isConfigured {
    final configured = _shopId.isNotEmpty && _secretKey.isNotEmpty;
    if (!configured) {
      print('❌ ЮКасса НЕ настроена!');
      print('   YOOKASSA_SHOP_ID: ${_shopId.isEmpty ? "пусто" : _shopId}');
      print('   YOOKASSA_SECRET_KEY: ${_secretKey.isEmpty ? "пусто" : "задан"}');
    }
    return configured;
  }

  // Проверка режима (тест/продакшн)
  static bool get isTestMode {
    return _mode == 'test';
  }

  static bool get isProductionMode {
    return _mode == 'production';
  }

  static String get currentMode => _mode;

  /// Вывод информации о текущем режиме (для отладки)
  void printCurrentMode() {
    print('');
    print('═══════════════════════════════════════════════════════');
    print('🔍 РЕЖИМ ЮКАССЫ');
    print('═══════════════════════════════════════════════════════');
    print('Режим: ${isProductionMode ? "💰 БОЕВОЙ (PRODUCTION)" : "🧪 ТЕСТОВЫЙ (TEST)"}');
    print('ShopId: $_shopId');
    
    if (_secretKey.startsWith('test_')) {
      print('Ключ: ✅ test_xxx... (ТЕСТОВЫЙ)');
    } else if (_secretKey.startsWith('live_')) {
      print('Ключ: ⚠️ live_xxx... (БОЕВОЙ!)');
    } else {
      print('Ключ: ${_secretKey.substring(0, 10)}...');
    }
    
    print('Настроен: ${isConfigured ? "✅ ДА" : "❌ НЕТ"}');
    print('═══════════════════════════════════════════════════════');
    print('');
  }

  /// Создание платежа через ЮКассу
  Future<Map<String, dynamic>?> createPayment({
    required String userId,
    required String userEmail,
    String? userName,
  }) async {
    // Проверяем конфигурацию
    if (!isConfigured) {
      print('❌ ОШИБКА: ЮКасса не настроена!');
      print('Проверьте файл .env:');
      print('- YOOKASSA_SHOP_ID должен быть заполнен');
      print('- YOOKASSA_SECRET_KEY должен быть заполнен');
      throw Exception('ЮКасса не настроена. Проверьте .env файл');
    }

    // Выводим режим для отладки
    printCurrentMode();

    try {
      final idempotenceKey = _uuid.v4();
      
      final requestBody = {
        'amount': {
          'value': subscriptionPrice,
          'currency': currency,
        },
        'confirmation': {
          'type': 'redirect',
          'return_url': _returnUrl,
        },
        'capture': true,
        'description': 'Flow Premium - подписка на 1 месяц',
        'metadata': {
          'user_id': userId,
          'user_email': userEmail,
          if (userName != null) 'user_name': userName,
          'subscription_type': 'premium',
          'duration_days': '30',
        },
        'receipt': {
          'customer': {
            'email': userEmail,
          },
          'items': [
            {
              'description': 'Flow Premium подписка',
              'quantity': '1',
              'amount': {
                'value': subscriptionPrice,
                'currency': currency,
              },
              'vat_code': 1,
            }
          ],
        },
      };

      final credentials = base64Encode(utf8.encode('$_shopId:$_secretKey'));
      
      print('💳 Создание платежа...');
      print('URL: $_apiUrl/payments');
      print('ShopID: $_shopId');
      
      final response = await http.post(
        Uri.parse('$_apiUrl/payments'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Idempotence-Key': idempotenceKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📊 Ответ: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isTest = data['test'] ?? false;
        
        print('✅ Платеж создан:');
        print('   ID: ${data['id']}');
        print('   Тестовый: ${isTest ? "✅ ДА" : "❌ НЕТ (БОЕВОЙ!)"}');
        print('   Статус: ${data['status']}');
        
        return {
          'payment_id': data['id'],
          'status': data['status'],
          'confirmation_url': data['confirmation']['confirmation_url'],
          'amount': data['amount']['value'],
          'test': isTest,
        };
      } else {
        print('❌ Ошибка создания платежа: ${response.statusCode}');
        print('Ответ: ${response.body}');
        
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['description'] ?? 'Неизвестная ошибка');
        } catch (e) {
          throw Exception('Ошибка создания платежа: ${response.statusCode}');
        }
      }
    } on http.ClientException catch (e) {
      print('❌ Ошибка сети: $e');
      throw Exception('Ошибка сети. Проверьте подключение к интернету.');
    } catch (e) {
      print('❌ Исключение: $e');
      rethrow;
    }
  }

  /// Проверка статуса платежа
  Future<Map<String, dynamic>?> getPaymentInfo(String paymentId) async {
    if (!isConfigured) {
      throw Exception('ЮКасса не настроена');
    }

    try {
      final credentials = base64Encode(utf8.encode('$_shopId:$_secretKey'));
      
      final response = await http.get(
        Uri.parse('$_apiUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Ошибка получения информации о платеже: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Исключение при получении информации о платеже: $e');
      return null;
    }
  }

  /// Отмена платежа
  Future<bool> cancelPayment(String paymentId) async {
    if (!isConfigured) return false;

    try {
      final idempotenceKey = _uuid.v4();
      final credentials = base64Encode(utf8.encode('$_shopId:$_secretKey'));
      
      final response = await http.post(
        Uri.parse('$_apiUrl/payments/$paymentId/cancel'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Idempotence-Key': idempotenceKey,
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Исключение при отмене платежа: $e');
      return false;
    }
  }

  /// Создание возврата
  Future<Map<String, dynamic>?> createRefund({
    required String paymentId,
    String? amount,
  }) async {
    if (!isConfigured) {
      throw Exception('ЮКасса не настроена');
    }

    try {
      final idempotenceKey = _uuid.v4();
      final credentials = base64Encode(utf8.encode('$_shopId:$_secretKey'));
      
      final requestBody = {
        'amount': {
          'value': amount ?? subscriptionPrice,
          'currency': currency,
        },
        'payment_id': paymentId,
      };

      final response = await http.post(
        Uri.parse('$_apiUrl/refunds'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Idempotence-Key': idempotenceKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Ошибка создания возврата: ${response.statusCode}');
        print('Ответ: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Исключение при создании возврата: $e');
      return null;
    }
  }

  /// Получение списка платежей
  Future<List<Map<String, dynamic>>?> getPaymentsList({
    DateTime? createdAtGte,
    DateTime? createdAtLte,
    int limit = 10,
  }) async {
    if (!isConfigured) return null;

    try {
      final credentials = base64Encode(utf8.encode('$_shopId:$_secretKey'));
      
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (createdAtGte != null) {
        queryParams['created_at.gte'] = createdAtGte.toIso8601String();
      }
      if (createdAtLte != null) {
        queryParams['created_at.lte'] = createdAtLte.toIso8601String();
      }

      final uri = Uri.parse('$_apiUrl/payments')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['items'] ?? []);
      } else {
        print('Ошибка получения списка платежей: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Исключение при получении списка платежей: $e');
      return null;
    }
  }

  /// Проверка доступности API
  Future<bool> checkConnection() async {
    if (!isConfigured) return false;

    try {
      final credentials = base64Encode(utf8.encode('$_shopId:$_secretKey'));
      
      final response = await http.get(
        Uri.parse('$_apiUrl/payments?limit=1'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Проверка соединения не удалась: $e');
      return false;
    }
  }
}