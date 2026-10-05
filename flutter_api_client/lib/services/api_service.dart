import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';

class ApiService {
  final String baseUrl =
      'https://tugas-deployment-web-seluler-production-ae3e.up.railway.app';

  /// GET Categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/categories'));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> jsonData;

        if (decodedData is List) {
          jsonData = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          jsonData = decodedData['data'];
        } else {
          throw Exception('Format JSON kategori tidak dikenali');
        }

        return jsonData.map((item) => Category.fromJson(item)).toList();
      } else {
        throw Exception(
          'Gagal mengambil kategori (status ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// GET — Ambil semua produk
  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/products'));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        List<dynamic> jsonData;
        if (decodedData is List) {
          jsonData = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('data')) {
          jsonData = decodedData['data'];
        } else {
          throw Exception('Format JSON tidak dikenali');
        }

        return jsonData.map((item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Gagal mengambil data dari server');
      }
    } catch (error) {
      throw Exception('Terjadi kesalahan: $error');
    }
  }

  /// POST — Tambah produk baru
  Future<Product> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return Product.fromJson(data.first);
        } else if (data is Map && data.containsKey('data')) {
          return Product.fromJson(data['data']);
        }
        return Product.fromJson(data);
      } else {
        // Tangkap pesan error validasi dari server
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
            if (errorData.containsKey('errors')) {
              errorMessage += '\n${errorData['errors'].toString()}';
            }
          } else {
            errorMessage = response.body;
          }
        } catch (_) {
          errorMessage = response.body;
        }

        throw Exception(
          'Gagal menambah produk (status ${response.statusCode}): $errorMessage',
        );
      }
    } catch (error) {
      throw Exception('Terjadi kesalahan: $error');
    }
  }

  /// PUT — Ubah produk
  Future<Product> updateProduct(int id, Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('data')) {
          return Product.fromJson(data['data']);
        }
        return Product.fromJson(data);
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('message')) {
            errorMessage = errorData['message'].toString();
            if (errorData.containsKey('errors')) {
              errorMessage += '\n${errorData['errors'].toString()}';
            }
          } else {
            errorMessage = response.body;
          }
        } catch (_) {
          errorMessage = response.body;
        }

        throw Exception(
          'Gagal mengubah produk (status ${response.statusCode}): $errorMessage',
        );
      }
    } catch (error) {
      throw Exception('Terjadi kesalahan: $error');
    }
  }

  /// DELETE — Hapus produk
  Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/products/$id'),
      );

      if (response.statusCode != 200 &&
          response.statusCode != 204 &&
          response.statusCode != 201) {
        throw Exception(
          'Gagal menghapus produk (status ${response.statusCode})',
        );
      }
    } catch (error) {
      throw Exception('Terjadi kesalahan: $error');
    }
  }
}
