// lib/services/webhook_handler.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Обработчик вебхуков от ЮКассы
/// 
/// ВАЖНО: Этот код используется на сервере (Cloud Functions или ваш backend)
/// Не размещайте его в мобильном приложении!
/// 
/// Пример использования с Firebase Cloud Functions:
/// ```javascript
/// const functions = require('firebase-functions');
/// const admin = require('firebase-admin');
/// 
/// exports.yookassaWebhook = functions.https.onRequest(async (req, res) => {
///   // Проверяем IP-адрес отправителя
///   const allowedIPs = [
///     '185.71.76.0/27',
///     '185.71.77.0/27',
///     '77.75.153.0/25',
///     '77.75.156.11',
///     '77.75.156.35',
///     '77.75.154.128/25',
///   ];
///   
///   // Получаем данные из тела запроса
///   const notification = req.body;
///   
///   if (notification.event === 'payment.succeeded') {
///     const payment = notification.object;
///     const userId = payment.metadata.user_id;
///     const durationDays = parseInt(payment.metadata.duration_days || '30');
///     
///     // Активируем подписку
///     const now = admin.firestore.Timestamp.now();
///     const expires = admin.firestore.Timestamp.fromDate(
///       new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000)
///     );
///     
///     await admin.firestore()
///       .collection('users')
///       .doc(userId)
///       .set({
///         subscription: {
///           isActive: true,
///           type: 'premium',
///           startedAt: now,
///           expiresAt: expires,
///           paymentId: payment.id,
///           amount: payment.amount.value,
///         }
///       }, { merge: true });
///     
///     // Сохраняем информацию о платеже
///     await admin.firestore()
///       .collection('payments')
///       .doc(payment.id)
///       .set({
///         userId: userId,
///         amount: payment.amount.value,
///         currency: payment.amount.currency,
///         status: payment.status,
///         createdAt: admin.firestore.Timestamp.fromDate(new Date(payment.created_at)),
///         paidAt: now,
///         metadata: payment.metadata,
///       });
///   }
///   
///   if (notification.event === 'payment.canceled') {
///     const payment = notification.object;
///     
///     // Обновляем статус платежа
///     await admin.firestore()
///       .collection('payments')
///       .doc(payment.id)
///       .set({
///         status: 'canceled',
///         canceledAt: admin.firestore.Timestamp.now(),
///         cancellationDetails: payment.cancellation_details,
///       }, { merge: true });
///   }
///   
///   if (notification.event === 'refund.succeeded') {
///     const refund = notification.object;
///     const userId = refund.metadata?.user_id;
///     
///     if (userId) {
///       // Деактивируем подписку
///       await admin.firestore()
///         .collection('users')
///         .doc(userId)
///         .set({
///           subscription: {
///             isActive: false,
///             type: 'free',
///             refundedAt: admin.firestore.Timestamp.now(),
///           }
///         }, { merge: true });
///     }
///     
///     // Сохраняем информацию о возврате
///     await admin.firestore()
///       .collection('refunds')
///       .doc(refund.id)
///       .set({
///         paymentId: refund.payment_id,
///         amount: refund.amount.value,
///         currency: refund.amount.currency,
///         status: refund.status,
///         createdAt: admin.firestore.Timestamp.fromDate(new Date(refund.created_at)),
///       });
///   }
///   
///   // Отвечаем 200 OK
///   res.status(200).send('OK');
/// });
/// ```

class WebhookHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Обработка уведомления о успешном платеже
  Future<void> handlePaymentSucceeded(Map<String, dynamic> payment) async {
    try {
      final userId = payment['metadata']['user_id'] as String;
      final durationDays = int.tryParse(
        payment['metadata']['duration_days'] ?? '30',
      ) ?? 30;

      final now = Timestamp.now();
      final expires = Timestamp.fromDate(
        DateTime.now().add(Duration(days: durationDays)),
      );

      await _firestore.collection('users').doc(userId).set({
        'subscription': {
          'isActive': true,
          'type': 'premium',
          'startedAt': now,
          'expiresAt': expires,
          'paymentId': payment['id'],
          'amount': payment['amount']['value'],
        }
      }, SetOptions(merge: true));

      // Сохраняем платеж в отдельную коллекцию
      await _firestore.collection('payments').doc(payment['id']).set({
        'userId': userId,
        'amount': payment['amount']['value'],
        'currency': payment['amount']['currency'],
        'status': payment['status'],
        'createdAt': Timestamp.fromDate(
          DateTime.parse(payment['created_at']),
        ),
        'paidAt': now,
        'metadata': payment['metadata'],
      });
    } catch (e) {
      print('Ошибка обработки успешного платежа: $e');
      rethrow;
    }
  }

  /// Обработка уведомления об отмене платежа
  Future<void> handlePaymentCanceled(Map<String, dynamic> payment) async {
    try {
      await _firestore.collection('payments').doc(payment['id']).set({
        'status': 'canceled',
        'canceledAt': Timestamp.now(),
        'cancellationDetails': payment['cancellation_details'],
      }, SetOptions(merge: true));
    } catch (e) {
      print('Ошибка обработки отмены платежа: $e');
      rethrow;
    }
  }

  /// Обработка уведомления об успешном возврате
  Future<void> handleRefundSucceeded(Map<String, dynamic> refund) async {
    try {
      final userId = refund['metadata']?['user_id'] as String?;

      if (userId != null) {
        await _firestore.collection('users').doc(userId).set({
          'subscription': {
            'isActive': false,
            'type': 'free',
            'refundedAt': Timestamp.now(),
          }
        }, SetOptions(merge: true));
      }

      // Сохраняем возврат
      await _firestore.collection('refunds').doc(refund['id']).set({
        'paymentId': refund['payment_id'],
        'amount': refund['amount']['value'],
        'currency': refund['amount']['currency'],
        'status': refund['status'],
        'createdAt': Timestamp.fromDate(
          DateTime.parse(refund['created_at']),
        ),
      });
    } catch (e) {
      print('Ошибка обработки возврата: $e');
      rethrow;
    }
  }

  /// Основной обработчик вебхуков
  Future<bool> handleWebhook(Map<String, dynamic> notification) async {
    try {
      final event = notification['event'] as String;
      final object = notification['object'] as Map<String, dynamic>;

      switch (event) {
        case 'payment.succeeded':
          await handlePaymentSucceeded(object);
          break;
        case 'payment.canceled':
          await handlePaymentCanceled(object);
          break;
        case 'refund.succeeded':
          await handleRefundSucceeded(object);
          break;
        default:
          print('Неизвестный тип события: $event');
      }

      return true;
    } catch (e) {
      print('Ошибка обработки вебхука: $e');
      return false;
    }
  }
}
