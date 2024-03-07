// ignore_for_file: use_build_context_synchronously
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:qonversion_flutter/qonversion_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<OfferingData> listOfOfferings = []; // Populate this with data

  QEntitlement? _activeEntitlement;

  // bool _isLoading = false;
  // Map<String, bool> _productLoadingStates = {};

  @override
  void initState() {
    super.initState();
    fetchOfferingsAndCheckStatus();
  }

  Future<void> fetchOfferingsAndCheckStatus() async {
    try {
      final qonversionInstance = Qonversion.getSharedInstance();

      // Fetch offerings
      final offerings = await qonversionInstance.offerings();
      for (final offering in offerings.availableOfferings) {
        final products = offering.products;
        setState(() {
          listOfOfferings
              .add(OfferingData(offeringId: offering.id, products: products));
        });
      }

      // Check purchase status
      final entitlements = await qonversionInstance.checkEntitlements();
      entitlements.forEach((key, value) {
        if (value.isActive) {
          setState(() {
            _activeEntitlement = value;
          });
        }
      });
    } catch (e) {
      print('Error in fetchOfferingsAndCheckStatus: $e');
    }
  }

  Future<bool> _purchaseProduct(QProduct product) async {
    try {
      final QPurchaseModel purchaseModel = product.toPurchaseModel();
      final purchaseResult =
          await Qonversion.getSharedInstance().purchase(purchaseModel);
      // Update the UI to reflect the purchase
      setState(() {
        _activeEntitlement = purchaseResult.entries.first.value;
        // Load the purchased product's details here (see explanation below)
      });
    } on QPurchaseException catch (e) {
      // ... (Error handling)
    } catch (e) {
      // ... (General error handling)
    } finally {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Qonversion In App Purchase"),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 400,
              child: _activeEntitlement != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Congratulations! You are eligible for the ${_activeEntitlement!.id} plan.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              color: Colors.green,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              "Purchased item: ${_activeEntitlement!.productId}.",
                              style: TextStyle(
                                  fontSize: 19,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Text(
                              "Valid until: ${_activeEntitlement!.expirationDate}.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 19,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      separatorBuilder: (context, index) {
                        return const SizedBox(
                          width: 12,
                        );
                      },
                      itemCount: listOfOfferings.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final offering = listOfOfferings[index];
                        return Container(
                          color: Colors.grey[100],
                          width: 110,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Offering ID: ${offering.offeringId}'),
                              const SizedBox(height: 30),
                              ListView.builder(
                                itemCount: offering.products.length,
                                shrinkWrap: true,
                                itemBuilder: (BuildContext context, int index) {
                                  final product = offering.products[index];
                                  return ProductItem(
                                      product: product,
                                      onPressed: _purchaseProduct);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class ProductItem extends StatefulWidget {
  final QProduct product;
  final Future<bool> Function(QProduct) onPressed;

  ProductItem({super.key, required this.product, required this.onPressed});

  @override
  State<ProductItem> createState() => _ProductItemState();
}

class _ProductItemState extends State<ProductItem> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.product.skProduct?.localizedTitle}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${widget.product.prettyPrice}  ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            style: const ButtonStyle(),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await widget.onPressed(widget.product);

              setState(() {
                _isLoading = false;
              });
            },
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text("Buy Product")),
        const SizedBox(height: 20), // Add this SizedBox for spacing
      ],
    );
  }
}

class OfferingData {
  String offeringId;
  List<QProduct> products;

  OfferingData({required this.offeringId, required this.products});
}
