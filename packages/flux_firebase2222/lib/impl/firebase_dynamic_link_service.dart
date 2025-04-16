// TODO(InspireUI Team): We will soon update a new alternative
// solution for FirebaseDynamicLinks as soon as possible
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:fstore/common/config.dart';
import 'package:fstore/common/constants.dart' show isAndroid, printLog;
import 'package:fstore/services/dynamic_link_service.dart';

class FirebaseDynamicLinkService extends DynamicLinkService {
  FirebaseDynamicLinkService({
    required super.linkService,
  });

  @override
  Future<void> initialize() async {
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) async {
      var uri = dynamicLinkData.link;
      final url = uri.toString();
      if (url.contains('page.link') ||
          url.contains(firebaseDynamicLinkConfig['uriPrefix'])) {
        uri = (await _unShortenUrl(url)) ?? uri;
      }
      unawaited(linkService.handleDynamicLink(uri));
    }).onError((e) {
      printLog('[firebase-dynamic-link] error: ${e.message}');
    });

    // If run below code on ios, the app will open dynamic link twice
    if (isAndroid) {
      var initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
      if (initialLink != null) {
        final deepLink = initialLink.link;
        printLog('[firebase-dynamic-link] getInitialLink: $deepLink');
        await linkService.handleDynamicLink(deepLink);
      }
    }
  }

  /// share product link that contains Dynamic link
  @override
  Future<String?> createDynamicLink({
    required String productUrl,
  }) async {
    var productParams = _dynamicLinkParameters(url: productUrl);
    var firebaseDynamicLink = await _generateFirebaseDynamicLink(productParams);
    printLog('[firebase-dynamic-link] $firebaseDynamicLink');
    return firebaseDynamicLink.toString();
  }

  DynamicLinkParameters _dynamicLinkParameters({required String url}) {
    return DynamicLinkParameters(
      uriPrefix: firebaseDynamicLinkConfig['uriPrefix'],
      link: Uri.parse(url),
      androidParameters: AndroidParameters(
        packageName: firebaseDynamicLinkConfig['androidPackageName'],
        minimumVersion: firebaseDynamicLinkConfig['androidAppMinimumVersion'],
      ),
      iosParameters: IOSParameters(
        bundleId: firebaseDynamicLinkConfig['iOSBundleId'],
        minimumVersion: firebaseDynamicLinkConfig['iOSAppMinimumVersion'],
        appStoreId: firebaseDynamicLinkConfig['iOSAppStoreId'],
      ),
    );
  }

  Future<Uri> _generateFirebaseDynamicLink(DynamicLinkParameters params) async {
    var dynamicLinks = FirebaseDynamicLinks.instance;

    if (firebaseDynamicLinkConfig['shortDynamicLinkEnable'] ?? false) {
      var shortDynamicLink = await dynamicLinks.buildShortLink(params);
      return shortDynamicLink.shortUrl;
    } else {
      return await dynamicLinks.buildLink(params);
    }
  }

  Future<Uri?> _unShortenUrl(String url) async {
    final uri = Uri.parse(url);
    final unShortenUrl =
        await FirebaseDynamicLinks.instance.getDynamicLink(uri);
    return unShortenUrl?.link;
  }
}
