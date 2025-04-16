import 'dart:async';

import 'package:flux_ui/flux_ui.dart' as store_model;
import 'package:graphql/client.dart';
import 'package:intl/intl.dart';

import '../../../../common/config.dart' show kShopifyPaymentConfig;
import '../../../../common/constants.dart';
import '../../../../models/cart/shopify_v2/cart_model_shopify.dart';
import '../../../../models/index.dart'
    show CartDataShopify, CartModel, PaymentMethod, ShippingMethod;
import '../../services/shopify_query.dart';
import '../../services/shopify_service.dart';

class ShopifyServiceV2 extends ShopifyService {
  static const apiVersion = '2025-01';

  ShopifyServiceV2({
    required super.domain,
    super.blogDomain,
    required super.accessToken,
    required super.client,
  });

  @override
  Future<List<ShippingMethod>> getShippingMethods({
    CartModel? cartModel,
    String? token,
    String? checkoutId,
    store_model.Store? store,
  }) async {
    try {
      if (checkoutId == null) {
        throw 'Please create a cart first.';
      }
      var list = <ShippingMethod>[];
      var newAddress = cartModel!.address!.toShopifyJson(version: 2);

      printLog('getShippingMethods with cartId $checkoutId');

      final options = MutationOptions(
        document: gql(ShopifyQuery.cartBuyerIdentifyUpdate),
        fetchPolicy: FetchPolicy.noCache,
        variables: {
          'cartId': checkoutId,
          'buyerIdentity': {
            'email': cartModel.address!.email,
            'deliveryAddressPreferences': [
              {
                'deliveryAddress': newAddress,
              }
            ]
          },
        },
      );

      final result = await client.mutate(options);

      if (result.hasException) {
        printLog(result.exception.toString());
        throw ('So sorry, We do not support shipping to your address.');
      }

      final checkout = await getCart(cartId: checkoutId);

      final deliveryGroups = checkout.deliverGroups;

      if (deliveryGroups.isEmpty) {
        throw ('So sorry, We do not support shipping to your address.');
      }

      for (final group in deliveryGroups) {
        for (final option in group.deliveryOptions) {
          final optionWithGroupId = option.toJson()
            ..addAll({
              'deliveryGroupId': group.id,
            });
          list.add(ShippingMethod.fromShopifyJsonV2(optionWithGroupId));
        }
      }

      return list;
    } catch (e, trace) {
      printLog('::::getShippingMethods shopify error');
      printError(e, trace);
      throw ('So sorry, We do not support shipping to your address.');
    }
  }

  @override
  Future<CartDataShopify> getCart({required String cartId}) async {
    try {
      final options = QueryOptions(
        document: gql(ShopifyQuery.fetchCart),
        fetchPolicy: FetchPolicy.noCache,
        variables: {'id': cartId},
      );

      final result = await client.query(options);

      if (result.hasException) {
        printLog(result.exception.toString());
        throw Exception(result.exception.toString());
      }

      printLog('getCart $result');

      return CartDataShopify.fromJson(result.data?['cart']);
    } catch (e, trace) {
      printLog('::::getCheckout shopify error');
      printError(e, trace);
      rethrow;
    }
  }

  @override
  Future<List<PaymentMethod>> getPaymentMethods({
    CartModel? cartModel,
    ShippingMethod? shippingMethod,
    String? token,
  }) async {
    try {
      var list = <PaymentMethod>[];

      list.add(PaymentMethod.fromJson({
        'id': '0',
        'title': 'Checkout Free',
        'description': '',
        'enabled': true,
      }));

      if (kShopifyPaymentConfig.paymentCardConfig.enable) {
        list.add(PaymentMethod.fromJson({
          'id': PaymentMethod.stripeCard,
          'title': 'Checkout Credit card',
          'description': '',
          'enabled': true,
        }));
      }

      if (kShopifyPaymentConfig.applePayConfig.enable && isIos) {
        list.add(PaymentMethod.fromJson({
          'id': PaymentMethod.stripeApplePay,
          'title': 'Checkout with ApplePay',
          'description': '',
          'enabled': true,
        }));
      }

      if (kShopifyPaymentConfig.googlePayConfig.enable && isAndroid) {
        list.add(PaymentMethod.fromJson({
          'id': PaymentMethod.stripeGooglePay,
          'title': 'Checkout with GooglePay',
          'description': '',
          'enabled': true,
        }));
      }

      return list;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CartDataShopify?> createCart(CartModelShopifyV2 cartModel) async {
    final cookie = cartModel.user?.cookie;
    try {
      var lineItems = [];

      final productVariationInCart = cartModel.cartItemMetaDataInCart.keys
          .where((e) => cartModel.cartItemMetaDataInCart[e]?.variation != null)
          .toList();
      for (var productId in productVariationInCart) {
        var variant = cartModel.cartItemMetaDataInCart[productId]!.variation!;
        var productCart = cartModel.productsInCart[productId];

        printLog('addItemsToCart $variant');

        lineItems.add({'merchandiseId': variant.id, 'quantity': productCart});
      }

      printLog('addItemsToCart lineItems $lineItems');
      final email = cartModel.address?.email;
      final options = MutationOptions(
        document: gql(ShopifyQuery.cartCreate),
        variables: {
          'input': {
            'lines': lineItems,
            'buyerIdentity': {
              'countryCode': countryCode,
              if (email != null) 'email': email,
              if (cookie != null) 'customerAccessToken': cookie,
            }
          },
          'langCode': cartModel.langCode?.toUpperCase(),
          'countryCode': countryCode,
        },
      );

      final result = await client.mutate(options);

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      final cart = result.data!['cartCreate']['cart'];

      printLog('addItemsToCart cart $cart');

      // start link checkout with user
      // final newCheckout = await (checkoutLinkUser(checkout['id'], cookie));

      final cartData = CartDataShopify.fromJson(cart ?? {});
      return cartData;
    } catch (e, trace) {
      printError('::::addItemsToCart shopify error', trace);
      rethrow;
    }
  }

  @override
  Future<CartDataShopify?> applyCouponWithCartId({
    required String cartId,
    required String discountCode,
  }) async {
    try {
      printLog('::::::::::applyCoupon $discountCode for $cartId');

      final options = MutationOptions(
        document: gql(ShopifyQuery.cartDiscountCodesUpdate),
        variables: {
          'cartId': cartId,
          'discountCodes': [discountCode],
        },
      );

      final result = await client.mutate(options);

      if (result.hasException) {
        printLog(result.exception.toString());
        throw Exception(result.exception.toString());
      }

      final cartData = result.data!['cartDiscountCodesUpdate']['cart'];

      return CartDataShopify.fromJson(cartData);
    } catch (e, trace) {
      printLog('::::applyCoupon shopify error');
      printError(e, trace);
      rethrow;
    }
  }

  @override
  Future<CartDataShopify?> removeCouponWithCartId(String cartId) async {
    try {
      printLog('::::::::::removeCoupon for $cartId::::::::::::::::');

      final options = MutationOptions(
        document: gql(ShopifyQuery.cartDiscountCodesUpdate),
        variables: {
          'cartId': cartId,
          'discountCodes': const [],
        },
      );

      final result = await client.mutate(options);

      if (result.hasException) {
        printLog(result.exception.toString());
        throw Exception(result.exception.toString());
      }

      final cartData = result.data!['cartDiscountCodesUpdate']['cart'];

      return CartDataShopify.fromJson(cartData);
    } catch (e, trace) {
      printLog('::::::::::::::::::: removeCoupon error ::::::::::::::::::::::');
      printError(e, trace);
      rethrow;
    }
  }

  @override
  Future<CartDataShopify> updateCartAttributes({
    required String cartId,
    required DateTime deliveryDate,
  }) async {
    var deliveryInfo = [];
    final dateFormat = DateFormat(DateTimeFormatConstants.ddMMMMyyyy);
    final dayFormat = DateFormat(DateTimeFormatConstants.weekday);
    final timeFormat = DateFormat(DateTimeFormatConstants.timeHHmmFormatEN);
    deliveryInfo = [
      {
        'key': 'Delivery Date',
        'value': dateFormat.format(deliveryDate),
      },
      {
        'key': 'Delivery Day',
        'value': dayFormat.format(deliveryDate),
      },
      {
        'key': 'Delivery Time',
        'value': timeFormat.format(deliveryDate),
      },
      // {
      //   'key': 'Date create',
      //   'value': timeFormat.format(DateTime.now()),
      // },
    ];
    final options = MutationOptions(
      document: gql(ShopifyQuery.cartAttributesUpdate),
      variables: <String, dynamic>{
        'cartId': cartId,
        'attributes': deliveryInfo,
      },
    );

    final result = await client.mutate(options);

    if (result.hasException) {
      printLog(result.exception.toString());
      throw Exception(result.exception.toString());
    }

    return CartDataShopify.fromJson(
        result.data!['cartAttributesUpdate']['cart']);
  }

  @override
  Future<CartDataShopify> updateCartNote({
    required String cartId,
    required String note,
  }) async {
    final options = MutationOptions(
      document: gql(ShopifyQuery.cartNoteUpdate),
      variables: <String, dynamic>{
        'cartId': cartId,
        'note': note,
      },
    );

    final result = await client.mutate(options);

    if (result.hasException) {
      printLog(result.exception.toString());
      throw Exception(result.exception.toString());
    }

    return CartDataShopify.fromJson(result.data!['cartNoteUpdate']['cart']);
  }

  @override
  Future<void> updateCartEmail({
    required String cartId,
    required String email,
  }) async {
    final options = MutationOptions(
      document: gql(ShopifyQuery.cartBuyerIdentifyUpdate),
      variables: <String, dynamic>{
        'cartId': cartId,
        'buyerIdentity': {
          'email': email,
        }
      },
    );

    final result = await client.mutate(options);

    if (result.hasException) {
      printLog(result.exception.toString());
      throw (result.exception.toString());
    }
  }

  @override
  Future<CartDataShopify?> updateShippingRateWithCartId(
    String cartId, {
    required String deliveryGroupId,
    required String deliveryOptionHandle,
  }) async {
    try {
      final options = MutationOptions(
        document: gql(ShopifyQuery.cartSelectedDeliveryOptionsUpdate),
        variables: <String, dynamic>{
          'cartId': cartId,
          'selectedDeliveryOptions': [
            {
              'deliveryGroupId': deliveryGroupId,
              'deliveryOptionHandle': deliveryOptionHandle,
            }
          ]
        },
      );
      final result = await client.mutate(options);

      if (result.hasException) {
        printLog(result.exception.toString());
      }

      final data = result.data!['cartSelectedDeliveryOptionsUpdate']['cart'];
      return CartDataShopify.fromJson(data);
    } catch (e, trace) {
      printLog('::::updateShippingRate shopify error');
      printError(e, trace);
      return null;
    }
  }
}
