import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/tools/tools.dart';
import '../../../models/index.dart' show Product, ProductModel, UserModel;
import '../../../models/product_variant_model.dart';
import '../../../services/index.dart';
import '../../../widgets/product/product_bottom_sheet.dart';
import '../../../widgets/product/widgets/heart_button.dart';
import '../../chat/vendor_chat.dart';
import '../product_detail_screen.dart';
import '../widgets/buy_button_widget.dart';
import '../widgets/index.dart';
import '../widgets/product_common_info.dart';
import '../widgets/product_image_list.dart';
import '../widgets/product_image_slider.dart';

class SimpleLayout extends StatefulWidget {
  final Product product;
  final bool isLoading;
  final ScrollController? scrollController;

  const SimpleLayout({
    required this.product,
    this.isLoading = false,
    this.scrollController,
  });

  @override
  // ignore: no_logic_in_create_state
  State<SimpleLayout> createState() => _SimpleLayoutState(product: product);
}

class _SimpleLayoutState extends State<SimpleLayout>
    with SingleTickerProviderStateMixin {
  late final _scrollController = widget.scrollController ?? ScrollController();
  final ValueNotifier<int> _selectIndexNotifier = ValueNotifier(0);

  late Product product;

  _SimpleLayoutState({required this.product});

  Map<String, String> mapAttribute = HashMap();
  late AnimationController _hideController;
  var top = 0.0;

  bool _isVisibleBuyButton = true;
  late List? listo=[];
  @override
  void initState() {
    super.initState();
// fetchData();
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );
  }
   Future<void> fetchData() async {
    
   List<Map<dynamic, dynamic>> dataList = await Provider.of<ProductModel>(context, listen: false).getMetafields(product.id);
    if (dataList.isNotEmpty) {
      setState(() {
        listo = dataList;
      });
    }
  }

  @override
  void didUpdateWidget(SimpleLayout oldWidget) {
    if (oldWidget.product.type != widget.product.type) {
      setState(() {
        product = widget.product;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _hideController.dispose();
    _selectIndexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final id = product.id;
    final meta = Provider.of<ProductModel>(context, listen: false).getMetafields(id);
    printLog("pppppppppppppppppppppppppppppppppppppppppppppppppppppppis");
    printLog(product.id.toString());

    final userModel = Provider.of<UserModel>(context, listen: false);
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: SafeArea(
        bottom: false,
        top: kProductDetail.safeArea,
        child: ChangeNotifierProvider(
          create: (_) => ProductModel(),
          child: Consumer<ProductVariantModel>(
            builder: (context, model, child) {
              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        Scaffold(
                          resizeToAvoidBottomInset: false,
                          floatingActionButton: (!ServerConfig()
                                      .isVendorType() ||
                                  !kConfigChat['EnableSmartChat'])
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(bottom: 30),
                                  child: VendorChat(
                                    user: userModel.user,
                                    store: product.store,
                                  ),
                                ),
                          backgroundColor:
                              Theme.of(context).colorScheme.background,
                          body: CustomScrollView(
                            controller: _scrollController,
                            slivers: <Widget>[
                              SliverAppBar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.background,
                                elevation: 1.0,
                                expandedHeight:
                                    kIsWeb ? 0 : height * kProductDetail.height,
                                pinned: true,
                                floating: false,
                                leading: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .primaryColorLight
                                        .withOpacity(0.7),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      onPressed: () {
                                        context
                                            .read<ProductModel>()
                                            .clearProductVariations();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                                actions: <Widget>[
                                  if (widget.isLoading != true)
                                    HeartButton(
                                      product: product,
                                      size: 20.0,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: CircleAvatar(
                                      backgroundColor: Theme.of(context)
                                          .primaryColorLight
                                          .withOpacity(0.7),
                                      child: IconButton(
                                        icon: const Icon(Icons.more_vert,
                                            size: 19),
                                        color: Theme.of(context).primaryColor,
                                        onPressed: () =>
                                            ProductDetailScreen.showMenu(
                                          context,
                                          widget.product,
                                          isLoading: widget.isLoading,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                flexibleSpace: Builder(builder: (context) {
                                  var item = Product.cloneFrom(product);
                                  if (!kProductDetail.showVideo &&
                                      item.videoUrl != null) {
                                    item.videoUrl = null;
                                  }
                                  return kIsWeb
                                      ? const SizedBox()
                                      : kProductDetail.productImageLayout.isList
                                          ? ProductImageList(
                                              product: item,
                                              onChange: (index) {
                                                _selectIndexNotifier.value =
                                                    index;
                                              },
                                              height: height *
                                                  kProductDetail.height *
                                                  0.8,
                                            )
                                          : ProductImageSlider(
                                              product: item,
                                              onChange: (index) {
                                                _selectIndexNotifier.value =
                                                    index;
                                              },
                                            );
                                }),
                              ),
                              SliverList(
                                delegate: SliverChildListDelegate(
                                  <Widget>[
                                    const SizedBox(height: 2),
                                    if (kIsWeb)
                                      ValueListenableBuilder<int>(
                                          valueListenable: _selectIndexNotifier,
                                          builder: (context, index, child) {
                                            return ProductGallery(
                                              product: widget.product,
                                              selectIndex: index,
                                            );
                                          }),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8.0,
                                        bottom: 4.0,
                                        left: 15,
                                        right: 15,
                                      ),
                                      child: widget.product.isGroupedProduct
                                          ? const SizedBox()
                                          : ProductTitle(product!),
                                    ),
                                    //Text("ddd"),
                          //          List.generate( meta!.length,(index) {
                          //         return ListTile(
                          //                     title: Text(model.keywords[index]),
                          //                     onTap: () {
                          //                       onTap(model.keywords[index]);
                          //                     });
                                              
                          // })

            //                 if(listo!.isNotEmpty)
            //                   Row(
            //                 children:[
            //                    Image.network('https://cdn.shopify.com/s/files/1/0810/7350/4566/files/1.png?v=1693233310', width: 60, height: 60),
            //                    SizedBox(width: 5),
            //                     Flexible(
            // child:
            //                    Text(listo![0]!["value"].toString(),
            //                     maxLines: 2, // Set maximum lines to 2
            //                   //overflow: TextOverflow.ellipsis,
            //                   textAlign: TextAlign.right),)
            //                 ]
            //               ),
            //               SizedBox(
            //                 height:3
            //               ), if(listo!.isNotEmpty)
            //                              Row(
            //                 children:[
            //                    Image.network('https://cdn.shopify.com/s/files/1/0810/7350/4566/files/3.png?v=1693233311', width: 60, height: 60),
            //                    SizedBox(width: 5),
            //                     Flexible(
            // child:
            //                    Text(listo![1]!["value"].toString(),
            //                     maxLines: 2, // Set maximum lines to 2
            //                   //overflow: TextOverflow.ellipsis,
            //                   textAlign: TextAlign.right),)
            //                 ]
            //               ),
            //                     SizedBox(
            //                 height:3
            //               ), if(listo!.isNotEmpty)
            //                              Row(
            //                 children:[
            //                    Image.network('https://cdn.shopify.com/s/files/1/0810/7350/4566/files/2.png?v=1693233311', width: 60, height: 60),
            //                    SizedBox(width: 5),
            //                     Flexible(
            // child:
            //                    Text(listo![2]!["value"].toString(),
            //                     maxLines: 2, // Set maximum lines to 2
            //                   //overflow: TextOverflow.ellipsis,
            //                   textAlign: TextAlign.right),)
            //                 ]
            //               ),
                                  ],
                                ),
                              ),
                              if (Services().widget.enableShoppingCart(
                                  product.copyWith(isRestricted: false)))
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    child: AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: ProductCommonInfo(
                                        product: widget.product,
                                        isLoading: widget.isLoading,
                                        wrapSliver: false,
                                      ),
                                    ),
                                  ),
                                ),
                              if (!Services().widget.enableShoppingCart(
                                      product.copyWith(isRestricted: false)) &&
                                  product.shortDescription != null &&
                                  product.shortDescription!.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15.0),
                                    child:ProductShortDescription(product),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    // horizontal: 15.0,
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15.0,
                                        ),
                                        child: Column(
                                          children: [
                                            
                                            Services()
                                                .widget
                                                .renderVendorInfo(product),
                                            ProductDescription(product),
                                            if (kProductDetail
                                                .showProductCategories)
                                              ProductDetailCategories(product),
                                            if (kProductDetail.showProductTags)
                                              ProductTag(product),
                                            Services()
                                                .widget
                                                .productReviewWidget(product),
                                          ],
                                        ),
                                      ),
                                      if (kProductDetail
                                              .showRelatedProductFromSameStore &&
                                          product.store?.id != null)
                                        RelatedProductFromSameStore(product),
                                      if (kProductDetail.showRelatedProduct)
                                        RelatedProduct(product),
                                      if (kProductDetail.showRecentProduct)
                                        RecentProducts(excludeProduct: product),
                                      const SizedBox(height: 50),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (Services().widget.enableShoppingCart(
                                product.copyWith(isRestricted: false)) &&
                            kAdvanceConfig.showBottomCornerCart)
                          Align(
                            alignment: Tools.isRTL(context)
                                ? Alignment.bottomLeft
                                : Alignment.bottomRight,
                            child: ExpandingBottomSheet(
                              hideController: _hideController,
                              onInitController: _onInitController,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (kProductDetail.fixedBuyButtonToBottom &&
                      _isVisibleBuyButton)
                    Container(
                      color: Theme.of(context).colorScheme.background,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: const SafeArea(
                        top: false,
                        child: BuyButtonWidget(),
                      ),
                    )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _onInitController(AnimationController controller) {
    controller.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        setState(() {
          _isVisibleBuyButton = false;
        });
      } else if (status == AnimationStatus.reverse) {
        setState(() {
          _isVisibleBuyButton = true;
        });
      }
    });
  }
}
