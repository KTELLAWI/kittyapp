import 'package:flutter/material.dart';

import '../../../generated/l10n.dart';
import '../../../models/entities/product.dart';
import '../action_button_mixin.dart';

class CartButton extends StatelessWidget with ActionButtonMixin {
  final Product product;
  final bool hide;
  final int quantity;
  final bool enableBottomAddToCart;

  const CartButton({
    Key? key,
    required this.product,
    required this.hide,
    this.enableBottomAddToCart = false,
    this.quantity = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hide) return 
     TextButton(
      child:Text(""),
        onPressed: () => {},
      style: TextButton.styleFrom(

        backgroundColor: Colors.transparent,
        disabledForegroundColor: Colors.white.withOpacity(0.38),
        padding: const EdgeInsets.only(left: 15, right:15 ),
        shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      
    ),));

    return 

     TextButton(
      style: TextButton.styleFrom(

        backgroundColor: Theme.of(context).primaryColor,
        disabledForegroundColor: Colors.white.withOpacity(0.38),
        padding: const EdgeInsets.only(left: 15, right:15 ),
        shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
      ),
      onPressed: () => addToCart(
        context,
        product: product,
        quantity: quantity,
        enableBottomAddToCart: enableBottomAddToCart,
      ),
      child: Text(
        S.of(context).addToCart,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: Colors.white,
              fontSize:10,
            ),
      ),
   
    );
  }
}
