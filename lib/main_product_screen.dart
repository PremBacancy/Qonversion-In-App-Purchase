// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:qonversion_flutter/qonversion_flutter.dart';

class MainProductScreen extends StatefulWidget {
  const MainProductScreen({super.key});

  @override
  State<MainProductScreen> createState() => _MainProductScreenState();
}

class _MainProductScreenState extends State<MainProductScreen> {
  @override
  void initState() {
    super.initState();
    fetchAndPrepareOfferings();
  }

  Future<void> fetchAndPrepareOfferings() async {
    // Fetch offerings
    final offerings = await Qonversion.getSharedInstance().offerings();
    for (final offering in offerings.availableOfferings) {
      List<QProduct> products = offering.products;
      setState(() {
        listOfOfferings
            .add(OfferingData(offeringId: offering.id, products: products));
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Qonversion In App Purchase"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 400,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (context, index) {
                  return const SizedBox(
                    width: 12,
                  );
                },
                itemCount: listOfOfferings.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return OfferingItem(offeringData: listOfOfferings[index]);
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: () async {
                try {
                  final Map<String, QEntitlement> entitlements =
                      await Qonversion.getSharedInstance().checkEntitlements();
                  entitlements.forEach((key, value) {
                    if (value.isActive) {
                      print("Active entitlement: $key");
                    }
                  });
                } catch (e) {
                  print(e);
                }
              },
              child: Container(
                child: const Text("Check Active Entitlements"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class OfferingItem extends StatefulWidget {
  final OfferingData offeringData;
  const OfferingItem({required this.offeringData});

  @override
  State<OfferingItem> createState() => _OfferingItemState();
}

class _OfferingItemState extends State<OfferingItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Offering ID: ${widget.offeringData.offeringId}'),
          const SizedBox(height: 30),
          Column(
            children: widget.offeringData.products
                .map((product) => SingleProductWidget(product: product))
                .toList(),
          )
        ],
      ),
    );
  }
}

class ProductWidget extends StatelessWidget {
  final QProduct product;
  const ProductWidget(this.product);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${product.skProduct?.localizedTitle}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${product.prettyPrice}  ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class OfferingData {
  String offeringId;
  List<QProduct> products;

  OfferingData({required this.offeringId, required this.products});
}

List<OfferingData> listOfOfferings = []; // Populate this with data

class SingleProductWidget extends StatefulWidget {
  final QProduct product;
  const SingleProductWidget({super.key, required this.product});

  @override
  State<SingleProductWidget> createState() => _SingleProductWidgetState();
}

class _SingleProductWidgetState extends State<SingleProductWidget> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProductWidget(widget.product),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
            style: const ButtonStyle(),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              try {
                final QPurchaseModel purchaseModel =
                    widget.product.toPurchaseModel();
                await Qonversion.getSharedInstance().purchase(purchaseModel);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text('Product purchased successfully'),
                    duration: Duration(
                        seconds: 2), // Adjust how long it stays visible
                  ),
                );
              } on QPurchaseException catch (e) {
                if (e.isUserCancelled) {
                  // Purchase canceled by the user
                }
                print("Error ${e}");
              } catch (e) {
                print(e);
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: _isLoading
                ? CircularProgressIndicator()
                : const Text("Buy Product")),
        const SizedBox(height: 20), // Add this SizedBox for spacing
      ],
    );
  }
}
