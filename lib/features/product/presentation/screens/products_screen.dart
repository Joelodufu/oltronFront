import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/discount_badge.dart';
import '../../../../core/widgets/rating_widget.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products.dart';
import '../widgets/product_card.dart';
import 'home_screen.dart';
import 'product_detail_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> products = [];
  bool _isRailExpanded = false;
  String? _productsError;

  @override
  void initState() {
    super.initState();
    // Defer the loading until after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    try {
      final getProducts = GetProducts(
        Provider.of<ProductRepository>(context, listen: false),
      );
      final loadedProducts = await getProducts();
      setState(() {
        products = loadedProducts;
        _productsError = null;
      });
    } catch (e) {
      setState(() {
        _productsError = 'Error loading products: $e';
      });
    }
  }

  Widget _buildNavigation(
    BuildContext context, {
    required bool isMobile,
    required bool isTablet,
    required bool isDesktop,
  }) {
    final destinations = [
      NavigationDestination(
        icon: Icons.home,
        label: 'Home',
        route: const HomeScreen(),
        isSelected: false,
      ),
      NavigationDestination(
        icon: Icons.store,
        label: 'Products',
        route: const ProductsScreen(),
        isSelected: true,
      ),
      NavigationDestination(
        icon: Icons.shopping_cart,
        label: 'Cart',
        route: const CartScreen(),
        isSelected: false,
      ),
      NavigationDestination(
        icon: Icons.person,
        label: 'Profile',
        route: const ProfileScreen(),
        isSelected: false,
      ),
    ];

    if (isMobile) {
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.computer,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Oltron Store',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ...destinations.map(
              (dest) => ListTile(
                leading: Icon(dest.icon),
                title: Text(
                  dest.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                selected: dest.isSelected,
                onTap: () {
                  Navigator.pop(context);
                  if (!dest.isSelected) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => dest.route),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      );
    } else {
      return NavigationRail(
        extended: isDesktop || (isTablet && _isRailExpanded),
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index != 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => destinations[index].route,
              ),
            );
          }
        },
        leading: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.computer,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  if (isDesktop || _isRailExpanded) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Oltron Store',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isTablet)
              IconButton(
                icon: Icon(
                  _isRailExpanded ? Icons.arrow_left : Icons.arrow_right,
                ),
                onPressed: () {
                  setState(() {
                    _isRailExpanded = !_isRailExpanded;
                  });
                },
              ),
          ],
        ),
        destinations:
            destinations
                .map(
                  (dest) => NavigationRailDestination(
                    icon: Icon(dest.icon),
                    label: Text(dest.label),
                    selectedIcon: Icon(
                      dest.icon,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                )
                .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    final crossAxisCount =
        isMobile
            ? 2
            : isTablet
            ? 3
            : 4;

    // Show snackbar for error if it exists
    if (_productsError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_productsError!)));
        _productsError = null; // Reset error after showing
      });
    }

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          'Products',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 20 : 24),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
        ],
        automaticallyImplyLeading: isMobile,
      ),
      drawer:
          isMobile
              ? _buildNavigation(
                context,
                isMobile: true,
                isTablet: false,
                isDesktop: false,
              )
              : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isMobile ? 8.0 : 12.0,
                mainAxisSpacing: isMobile ? 8.0 : 12.0,
                childAspectRatio: isMobile ? 0.7 : 0.75,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final double discount = 0.2;
                final double rating = 3.0;
                final double discountedPrice = product.price * (1 - discount);

                return ProductCard(
                  product: product,
                  discount: discount,
                  rating: rating,
                  discountedPrice: discountedPrice,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );

    return isMobile
        ? scaffold
        : Row(
          children: [
            _buildNavigation(
              context,
              isMobile: false,
              isTablet: isTablet,
              isDesktop: isDesktop,
            ),
            Expanded(child: scaffold),
          ],
        );
  }
}

class NavigationDestination {
  final IconData icon;
  final String label;
  final Widget route;
  final bool isSelected;

  NavigationDestination({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
  });
}
