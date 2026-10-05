import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_page.dart';
import 'product_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();

  List<Product> _products = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _api.getProducts();
      if (!mounted) return;
      setState(() {
        _products = result;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  /// Buka halaman lain, lalu segarkan ringkasan saat kembali.
  Future<void> _go(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  int _stockOf(Product p) => int.tryParse(p.stock.toString()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final total = _products.length;
    final low = _products.where((p) {
      final s = _stockOf(p);
      return s > 0 && s <= 5;
    }).length;
    final out = _products.where((p) => _stockOf(p) <= 0).length;

    final attention = _products.where((p) => _stockOf(p) <= 5).toList()
      ..sort((a, b) => _stockOf(a).compareTo(_stockOf(b)));

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              // ── Hero ──
              // (Greeting dihilangkan sesuai permintaan)
              _Hero(),
              const SizedBox(height: 20),

              // ── Ringkasan ──
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total produk',
                      value: _loading ? null : '$total',
                      icon: Icons.inventory_2_rounded,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Stok menipis',
                      value: _loading ? null : '$low',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Stok habis',
                      value: _loading ? null : '$out',
                      icon: Icons.remove_shopping_cart_rounded,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
              if (_failed) ...[
                const SizedBox(height: 12),
                _InlineNotice(
                  message:
                      'Ringkasan belum bisa dimuat. Tarik layar untuk coba lagi.',
                  color: scheme.error,
                ),
              ],
              const SizedBox(height: 28),

              // ── Menu Utama ──
              Text(
                'Akses Cepat', // Ganti dari "Mulai dari sini"
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.inventory_2_outlined,
                title: 'Daftar produk',
                subtitle: 'Cari, ubah, dan hapus produk',
                color: scheme.primary,
                onTap: () => _go(const ProductPage()),
              ),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Tambah produk',
                subtitle: 'Simpan produk baru ke katalog',
                color: Colors.green.shade700,
                onTap: () => _go(const ProductFormPage()),
              ),

              // ── Perlu Perhatian ──
              if (!_loading && attention.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  'Perlu Perhatian', // Ganti dari "Perlu diisi ulang"
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Segera perbarui stok produk berikut', // Teks bantuan yang lebih enak dibaca
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                for (final p in attention.take(3)) ...[
                  _AttentionTile(
                    product: p,
                    stock: _stockOf(p),
                    onTap: () => _go(ProductFormPage(product: p)),
                  ),
                  const SizedBox(height: 8),
                ],
                if (attention.length > 3)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _go(const ProductPage()),
                      child: Text('Lihat ${attention.length - 3} lainnya'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Hero ─────────────────────────
class _Hero extends StatelessWidget {
  // Widget ini tidak lagi memerlukan parameter greeting
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.tertiary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: _Circle(
                size: 140,
                color: scheme.onPrimary.withOpacity(0.10),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -50,
              child: _Circle(
                size: 110,
                color: scheme.onPrimary.withOpacity(0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Katalog Produk',
                          style: text.headlineMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kelola produk Anda dengan mudah dan cepat.',
                          style: TextStyle(
                            color: scheme.onPrimary.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 34,
                      color: scheme.onPrimary,
                    ),
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

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ───────────────────────── Stat Card ─────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String? value; // null = sedang memuat
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          if (value == null)
            Container(
              width: 28,
              height: 22,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            Text(
              value!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Menu Tile ─────────────────────────
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Attention Tile ─────────────────────────
class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.product,
    required this.stock,
    required this.onTap,
  });

  final Product product;
  final int stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final habis = stock <= 0;
    final color = habis ? scheme.error : Colors.orange.shade800;

    return Material(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                habis
                    ? Icons.error_outline_rounded
                    : Icons.warning_amber_rounded,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                habis ? 'Habis' : 'Sisa $stock',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, required this.color});
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: TextStyle(color: color, fontSize: 12)),
        ),
      ],
    );
  }
}
