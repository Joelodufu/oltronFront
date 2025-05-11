import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oltron/features/product/domain/repositories/product_repository.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_product_by_id.dart';
import '../../../cart/domain/entities/cart_item.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId})
    : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? product;
  int _currentImageIndex = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _initDeepLinking();
  }

  void _initDeepLinking() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null && initialLink.contains('product/')) {
        final uri = Uri.parse(initialLink);
        final productId = int.tryParse(uri.pathSegments.last);
        if (productId != null && productId != widget.productId) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: productId),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
    }

    _sub = linkStream.listen(
      (String? link) {
        if (link != null && link.contains('product/')) {
          final uri = Uri.parse(link);
          final productId = int.tryParse(uri.pathSegments.last);
          if (productId != null && productId != widget.productId) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(productId: productId),
              ),
            );
          }
        }
      },
      onError: (err) {
        // Handle deep link errors
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final getProductById = GetProductById(
        Provider.of<ProductRepository>(context, listen: false),
      );
      final loadedProduct = await getProductById(widget.productId);
      setState(() {
        product = loadedProduct;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading product: $e')));
    }
  }

  void _launchWhatsApp() async {
    if (product == null) return;

    final String phoneNumber = AppConstants.whatsappNumber;
    final String message =
        'Hello, I am interested in this product:\n\n'
        'Name: ${product!.name}\n'
        'Price: ₦${product!.price}\n'
        'Description: ${product!.description}\n'
        'Image: ${product!.images.isNotEmpty ? product!.images[0] : 'No image available'}\n\n'
        'Please provide more details!';

    final String encodedMessage = Uri.encodeComponent(message);
    final String whatsappUrl =
        'https://wa.me/$phoneNumber?text=$encodedMessage';

    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  void _shareProduct() async {
    if (product == null) return;

    final String deepLink = 'https://oltronstore.com/product/${product!.id}';
    final String shareText =
        'Check out this product!\n\n'
        'Name: ${product!.name}\n'
        'Price: ₦${product!.price}\n'
        'Description: ${product!.description}\n'
        'Image: ${product!.images.isNotEmpty ? product!.images[0] : 'No image available'}\n'
        '$deepLink';

    await launchUrl(
      Uri.parse(
        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(shareText)}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  void _addToCart() {
    if (product == null) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addToCart(CartItem(product: product!, quantity: 1));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added ${product!.name} to cart')));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product?.name ?? 'Product Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 20 : 24),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _shareProduct),
          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ),
      body:
          product == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl:
                              product!.images.isNotEmpty
                                  ? product!.images[_currentImageIndex]
                                  : 'https://via.placeholder.com/300',
                          height: isMobile ? 400 : 400,
                          width: double.infinity,
                          fit: BoxFit.fitHeight,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        ),
                        if (product!.images.length > 1) ...[
                          Positioned(
                            left: 10,
                            top: isMobile ? 80 : 130,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentImageIndex =
                                      (_currentImageIndex - 1) %
                                      product!.images.length;
                                });
                              },
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: isMobile ? 80 : 130,
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  _currentImageIndex =
                                      (_currentImageIndex + 1) %
                                      product!.images.length;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (product!.images.length > 1)
                      SizedBox(
                        height: isMobile ? 60 : 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: product!.images.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: product!.images[index],
                                  width: isMobile ? 50 : 70,
                                  height: isMobile ? 50 : 70,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                  errorWidget:
                                      (context, url, error) =>
                                          const Icon(Icons.error),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product!.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontSize: isMobile ? 20 : 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₦${product!.price}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: isMobile ? 18 : 22,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product!.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontSize: isMobile ? 14 : 16),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _addToCart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    'Add to Cart',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontSize: isMobile ? 14 : 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _launchWhatsApp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    'Buy Now',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
