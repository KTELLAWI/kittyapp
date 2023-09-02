import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/index.dart';
import '../../../services/services.dart';
import '../../../widgets/common/flux_image.dart';
import '../../../widgets/product/widgets/quantity_selection.dart';

const _kProductItemHeight = 100.0;

class ProductReviewWidget extends StatelessWidget {
  final ProductItem item;
  const ProductReviewWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context, listen: false);
    final currency = appModel.currency;
    final currencyRate = appModel.currencyRate;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Container(
      height: _kProductItemHeight,
      margin: const EdgeInsetsDirectional.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: FluxImage(
              imageUrl: item.product?.imageFeature ?? '',
              fit: BoxFit.fitHeight,
              width: _kProductItemHeight,
              height: _kProductItemHeight,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  item.name ?? '',
                  style: TextStyle(
                    color: secondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Text(
                  Services().widget.getPriceItemInCart(
                      item.product!, null, currencyRate, currency)!,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                QuantitySelection(
                  enabled: false,
                  color: secondaryColor,
                  value: item.quantity,
                  useNewDesign: false,
                  width: 60,
                  height: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
