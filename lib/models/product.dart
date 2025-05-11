class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final List<String> images;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      description: json['description'],
      images: List<String>.from(json['images']),
    );
  }
}
