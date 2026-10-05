class Product {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final int price;
  final int stock;
  final String categoryName;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.categoryName = '',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] != null
          ? num.parse(json['price'].toString()).toInt()
          : 0,
      stock: json['stock'] != null ? int.parse(json['stock'].toString()) : 0,
      categoryName:
          (json['category'] is Map && json['category']['name'] != null)
          ? json['category']['name']
          : 'Lainnya',
    );
  }

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
  };
}
