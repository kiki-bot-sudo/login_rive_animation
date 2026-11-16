import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Map<String, dynamic>>> _products;

  @override
  void initState() {
    super.initState();
    _products = fetchProducts();
  }

  String get _baseUrl {
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredUrl.isNotEmpty) return configuredUrl;

    // Flutter Web and Android emulator defaults for a local Spring Boot server.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/products'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('El servidor respondió con HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const FormatException('La respuesta de /products no es una lista');
    }

    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos del mercado de Enrique')),
      // 6.3 Esperar la petición HTTP y dibujar según el estado del Future.
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudieron cargar los productos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        _products = fetchProducts();
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final products = snapshot.data ?? const [];
          if (products.isEmpty) {
            return const Center(child: Text('No hay productos disponibles.'));
          }

          // 6.4 Mostrar los productos que devolvió Spring Boot.
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final name = product['name']?.toString() ?? 'Producto';
              final price = product['price']?.toString() ?? '—';
              final stock = product['stock']?.toString() ?? '—';
              final active = product['active'] == true;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(name),
                  subtitle: Text('Precio: \$$price · Existencias: $stock'),
                  trailing: Icon(
                    active ? Icons.check_circle : Icons.remove_circle,
                    color: active ? Colors.green : Colors.grey,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
