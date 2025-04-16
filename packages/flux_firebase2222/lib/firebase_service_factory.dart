/// Service
import 'package:fstore/services/firebase/firebase_analytics_service.dart';

import 'firebase_auth_service.dart';
import 'firebase_remote_service.dart';

import 'impl/firebase_analytics_service_impl.dart';
import 'impl/firebase_auth/firebase_auth_service_impl.dart';
import 'impl/firebase_remote_service_impl.dart';

class FirebaseServiceFactory {
  static T? create<T>() {
    switch (T) {
      case const (FirebaseAuthService):
        return FirebaseAuthServiceImpl() as T;
      case const (FirebaseAnalyticsService):
        return FirebaseAnalyticsServiceImpl() as T;
      case const (FirebaseRemoteServices):
        return FirebaseRemoteServicesImpl() as T;
      default:
        return null;
    }
  }
}
