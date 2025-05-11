import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../components/product_card.dart';
import '../components/discount_badge.dart';
import '../components/rating_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  List<Product> products = [];
  List<String> categories = [];
  String? selectedCategory;
  final TextEditingController searchController = TextEditingController();
  bool _isShiftRightPressed = false; // Track Shift Right key state
  bool _isRailExpanded = false; // Track NavigationRail expansion on tablet

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    try {
      final loadedCategories = await apiService.getCategories();
      setState(() {
        categories = loadedCategories;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
    }
  }

  Future<void> _loadProducts() async {
    try {
      final loadedProducts = await apiService.getProducts(
        category: selectedCategory,
        search: searchController.text.isEmpty ? null : searchController.text,
      );
      setState(() {
        products = loadedProducts;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
    }
  }

  // Reusable navigation builder for Drawer and NavigationRail
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
        isSelected: true,
      ),
      NavigationDestination(
        icon: Icons.store,
        label: 'Products',
        route: const ProductsScreen(),
        isSelected: false,
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
                  Navigator.pop(context); // Close drawer
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
        selectedIndex: 0, // Home is selected
        onDestinationSelected: (index) {
          if (index != 0) {
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
                      color: Theme.of(context).colorScheme.secondary,
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
    final avatarRadius = isMobile ? 24.0 : 32.0;
    final adsWidth = isMobile ? screenWidth : screenWidth * 0.8;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(
          'Oltron Store',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: isMobile ? 20 : 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(apiService),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
        ],
        automaticallyImplyLeading: isMobile, // Show hamburger only on mobile
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
            child: Column(
              children: [
                // Ads Card
                if (products.isNotEmpty && products[0].images.isNotEmpty)
                  Container(
                    width: adsWidth,
                    margin: EdgeInsets.all(isMobile ? 8.0 : 16.0),
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedNetworkImage(
                          imageUrl: products[0].images[0],
                          width: isMobile ? 80 : 120,
                          height: isMobile ? 80 : 120,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (context, url, error) => const Icon(Icons.error),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                products[0].name,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontSize: isMobile ? 18 : 22),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₦${products[0].price}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey[600],
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₦${(products[0].price * 0.8).toStringAsFixed(2)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                products[0].description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontSize: isMobile ? 12 : 14),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ProductDetailScreen(
                                            productId: products[0].id,
                                          ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Shop Now',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(
                                    fontSize: isMobile ? 14 : 16,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Category Bar
                SizedBox(
                  height: isMobile ? 80 : 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8.0 : 12.0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory =
                                  selectedCategory == category
                                      ? null
                                      : category;
                              _loadProducts();
                            });
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor:
                                    selectedCategory == category
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.secondary
                                        : Colors.grey.shade200,
                                child: Icon(
                                  category == 'Processor'
                                      ? Icons.computer
                                      : Icons.videocam,
                                  color:
                                      selectedCategory == category
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.onSecondary
                                          : Colors.grey,
                                  size: isMobile ? 24 : 32,
                                ),
                              ),
                              Text(
                                category,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(fontSize: isMobile ? 12 : 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Product Cards
                GridView.builder(
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
                    final double discount = 0.2; // 20% discount placeholder
                    final double rating = 3.0; // 3.0 rating placeholder
                    final double discountedPrice =
                        product.price * (1 - discount);

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
              ],
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

class ProductSearchDelegate extends SearchDelegate {
  final ApiService apiService;

  ProductSearchDelegate(this.apiService);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final crossAxisCount =
        isMobile
            ? 2
            : isTablet
            ? 3
            : 4;

    return FutureBuilder<List<Product>>(
      future: apiService.getProducts(search: query),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final products = snapshot.data!;
          return GridView.builder(
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
              return Card(
                child: InkWell(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedNetworkImage(
                        imageUrl:
                            product.images.isNotEmpty
                                ? product.images[0]
                                : 'https://via.placeholder.com/150',
                        height: isMobile ? 100 : 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.error),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontSize: isMobile ? 14 : 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '₦${product.price}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontSize: isMobile ? 12 : 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
