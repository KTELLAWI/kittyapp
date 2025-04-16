import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/widgets/coupon_card.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/cart/shopify_v2/cart_model_shopify.dart';
import '../../../models/entities/coupon.dart';
import '../../../models/index.dart'
    show CartModel, Coupons, Order, PaymentMethod;
import '../../../modules/analytics/analytics.dart';
import '../../../routes/flux_navigate.dart';
import '../../../screens/index.dart'
    show PaymentWebview, WebviewCheckoutSuccessScreen;
import '../index.dart';
import 'services/shopify_service.dart';

class ShopifyWidgetV2 extends ShopifyWidget {
  ShopifyWidgetV2(ShopifyServiceV2 super.shopifyService);

  @override
  Future<void> applyCoupon(
    context, {
    Coupons? coupons,
    String? code,
    Function? success,
    Function? error,
    bool cartChanged = false,
  }) async {
    final cartModel =
        Provider.of<CartModel>(context, listen: false) as CartModelShopifyV2;
    try {
      var cartDataShopify = cartModel.cartDataShopify;

      if (cartChanged || cartDataShopify == null) {
        cartDataShopify = await shopifyService.createCart(cartModel);
      }

      if (cartDataShopify == null) {
        error!('Cannot apply coupon for now. Please try again later.');
        return;
      }
      cartModel.setCartDataShopify(cartDataShopify);

      final cartAppliedCoupon = await shopifyService.applyCouponWithCartId(
        cartId: cartDataShopify.id,
        discountCode: code!,
      );

      cartModel.setCartDataShopify(cartAppliedCoupon);
      final coupon = cartAppliedCoupon?.discountCodeApplied;
      if (cartAppliedCoupon != null && coupon != null) {
        printLog(
            '::::::::::::::::::: applyCoupon success ::::::::::::::::::::::');
        printLog('Cart ID: ${cartAppliedCoupon.id} applied coupon: [$coupon]');
        success!(Discount(
            discountValue: cartAppliedCoupon.totalCartLineItemDiscountAmount,
            coupon: Coupon(
              code: coupon,
              amount: cartAppliedCoupon.totalCartLineItemDiscountAmount,
              discountType: CouponType.fromShopify(cartAppliedCoupon
                  .discountAllocations
                  .firstOrNull
                  ?.discountApplication
                  .type
                  .name),
            )));
        return;
      }

      error!(S.of(context).couponInvalid);
    } on Exception catch (e, trace) {
      printLog('::::::::::::::::::: applyCoupon error ::::::::::::::::::::::');
      printError(e, trace);
      error!(e.toString());
    }
  }

  @override
  Future<void> removeCoupon(context) async {
    final cartModel = Provider.of<CartModel>(context, listen: false);
    final cartDataShopify = cartModel.cartDataShopify;
    if (cartDataShopify == null) return;
    try {
      final cartRemovedCoupon =
          await shopifyService.removeCouponWithCartId(cartDataShopify.id);

      printLog(
          '::::::::::::::::::: removeCoupon success ::::::::::::::::::::::');
      printLog('Cart ID: ${cartRemovedCoupon?.id} removed coupon');
      cartModel.setCartDataShopify(cartRemovedCoupon);
    } catch (e, trace) {
      printLog('::::::::::::::::::: removeCoupon error ::::::::::::::::::::::');
      printError(e, trace);
    }
  }

  @override
  Map<dynamic, dynamic> getPaymentUrl(context) {
    return {
      'headers': {},
      'url': Provider.of<CartModel>(context, listen: false)
          .cartDataShopify
          ?.checkoutUrl
    };
  }

  @override
  Future<void> doCheckout(
    context, {
    Function? success,
    Function? loading,
    Function? error,
  }) async {
    final cartModel =
        Provider.of<CartModel>(context, listen: false) as CartModelShopifyV2;

    final currentCart = cartModel.cartDataShopify;
    final discountCodeApplied = currentCart?.discountCodeApplied;

    try {
      final cartDataShopify = await shopifyService.createCart(cartModel);
      if (cartDataShopify == null) {
        error!('Cannot create cart right now. Please try again later.');
        return;
      }
      cartModel.setCartDataShopify(cartDataShopify);

      if (discountCodeApplied != null) {
        final cartAppliedCoupon = await shopifyService.applyCouponWithCartId(
          cartId: cartDataShopify.id,
          discountCode: discountCodeApplied,
        );
        cartModel.setCartDataShopify(cartAppliedCoupon);
      }

      if (kPaymentConfig.enableOnePageCheckout) {
        /// Navigate to Webview payment

        String? orderNum;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebview(
              url: cartDataShopify.checkoutUrl,
              token: cartModel.user?.cookie,
              onFinish: (number) async {
                orderNum = number;
              },
            ),
          ),
        );
        if (orderNum != null && !kIsWeb) {
          loading!(true);
          cartModel.clearCart();
          Analytics.triggerPurchased(
              Order(
                number: orderNum,
                total: cartDataShopify.cost.totalAmount(),
                id: '',
              ),
              context);
          final user = cartModel.user;
          if (user != null && user.isGuest == false) {
            final order = await shopifyService.getLatestOrder(
                cookie: cartModel.user?.cookie ?? '');
            if (order != null) {
              orderNum = order.number;
            }
          }
          if (kPaymentConfig.showWebviewCheckoutSuccessScreen) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WebviewCheckoutSuccessScreen(
                  order: Order(number: orderNum),
                ),
              ),
            );
          }
        }
        loading!(false);
        return;
      }
      success!();
    } catch (e) {
      error!(e.toString());
    }
  }

  @override
  void placeOrder(
    context, {
    required CartModel cartModel,
    PaymentMethod? paymentMethod,
    Function? onLoading,
    Function? success,
    Function? error,
  }) async {
    {
      final cartDataShopify = cartModel.cartDataShopify;
      final cartId = cartDataShopify?.id;
      if (cartId == null) {
        error!('Cart is empty');
        return;
      }
      final deliveryDate = cartModel.selectedDate?.dateTime;
      if (deliveryDate != null) {
        await shopifyService.updateCartAttributes(
          cartId: cartModel.cartDataShopify!.id,
          deliveryDate: deliveryDate,
        );
      }

      final note = cartModel.notes;
      if (note != null) {
        await shopifyService.updateCartNote(
          cartId: cartId,
          note: note,
        );
      }

      String? orderNum;
      final user = cartModel.user;
      await FluxNavigate.push(
        MaterialPageRoute(
          builder: (context) => PaymentWebview(
            token: cartModel.user?.cookie,
            url: cartModel.cartDataShopify!.checkoutUrl,
            onFinish: (number) async {
              // Success
              orderNum = number;
              if (number == '0') {
                if (user != null && user.isGuest == false) {
                  final order = await shopifyService.getLatestOrder(
                      cookie: cartModel.user?.cookie ?? '');
                  if (order == null) return error!('Checkout failed');
                  Analytics.triggerPurchased(
                      Order(
                        number: orderNum,
                        total: cartModel
                                .cartDataShopify?.cost.totalAmount.amount ??
                            0,
                        id: '',
                      ),
                      context);
                  success!(order);
                  return;
                }
                success!(Order());
                return;
              }
            },
            onClose: () {
              // Check in case the payment is successful but the webview is still displayed, need to press the close button
              if (orderNum != '0') {
                error!('Payment cancelled');
                return;
              }
            },
          ),
        ),
        forceRootNavigator: true,
        context: context,
      );
      onLoading!(false);
    }
  }
}
