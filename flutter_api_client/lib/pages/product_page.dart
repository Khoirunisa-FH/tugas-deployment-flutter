import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_form_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

enum _Sort { terbaru, termurah, termahal }

const _sortLabels = {
  _Sort.terbaru: 'Terbaru',
  _Sort.termurah: 'Harga terendah',
  _Sort.termahal: 'Harga tertinggi',
};

class _ProductPageState extends State<ProductPage> {
  final ApiService apiService = ApiService();

  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  String _query = '';
  String? _category; // null = semua kategori
  _Sort _sort = _Sort.terbaru;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  /// [silent = true] → data lama tetap tampil selagi memuat ulang.
  Future<void> _fetchProducts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await apiService.getProducts();
      if (mounted) {
        setState(() {
          _products = result;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _rupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final digits = number.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }

  double _priceOf(Product p) => double.tryParse(p.price.toString()) ?? 0;

  List<String> get _categories {
    final names = _products.map((p) => p.categoryName).toSet().toList();
    names.sort();
    return names;
  }

  List<Product> _apply(List<Product> data) {
    final q = _query.trim().toLowerCase();
    final list = data.where((p) {
      final matchQuery = q.isEmpty || p.name.toLowerCase().contains(q);
      final matchCat = _category == null || p.categoryName == _category;
      return matchQuery && matchCat;
    }).toList();

    switch (_sort) {
      case _Sort.terbaru:
        list.sort((a, b) => b.id.compareTo(a.id));
      case _Sort.termurah:
        list.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
      case _Sort.termahal:
        list.sort((a, b) => _priceOf(b).compareTo(_priceOf(a)));
    }
    return list;
  }

  Future<void> _openForm([Product? p]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: p)),
    );
    if (result == true && mounted) _fetchProducts(silent: true);
  }

  Future<void> _delete(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(ctx).colorScheme.error,
          size: 32,
        ),
        title: const Text('Hapus produk?'),
        content: Text(
          '"${p.name}" akan dihapus dari katalog dan tidak bisa dikembalikan.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await apiService.deleteProduct(p.id);
      if (!mounted) return;
      _snack('"${p.name}" dihapus');
      _fetchProducts(silent: true);
    } catch (e) {
      if (mounted) _snack('Gagal menghapus: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: error ? scheme.error : scheme.inverseSurface,
          content: Text(msg),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: _buildBody(scheme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah produk'),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    final data = _apply(_products);
    final showList = !_loading && _error == null && _products.isNotEmpty;

    return RefreshIndicator(
      edgeOffset: 120,
      onRefresh: () => _fetchProducts(silent: true),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text(
              'Daftar produk',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: scheme.surfaceContainerLowest,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: () => _fetchProducts(silent: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (showList) ...[
            SliverToBoxAdapter(child: _buildSearch(scheme)),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            SliverToBoxAdapter(child: _buildCountRow(scheme, data.length)),
          ],
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _LoadingList(),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StateMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Produk gagal dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                actionLabel: 'Coba lagi',
                onAction: () => _fetchProducts(),
              ),
            )
          else if (_products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StateMessage(
                icon: Icons.inventory_2_outlined,
                title: 'Belum ada produk',
                message: 'Tambahkan produk pertama Anda, nanti tampil di sini.',
                actionLabel: 'Tambah produk',
                onAction: () => _openForm(),
              ),
            )
          else if (data.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StateMessage(
                icon: Icons.search_off_rounded,
                title: 'Produk tidak ditemukan',
                message: 'Coba kata kunci lain atau ganti kategori.',
                actionLabel: 'Atur ulang filter',
                onAction: () => setState(() {
                  _query = '';
                  _category = null;
                }),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList.separated(
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = data[index];
                  return _ProductCard(
                    key: ValueKey(p.id),
                    product: p,
                    price: _rupiah(p.price),
                    onEdit: () => _openForm(p),
                    onDelete: () => _delete(p),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearch(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari nama produk',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _query = ''),
                ),
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withOpacity(0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: scheme.primary, width: 1.6),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final cats = _categories;
    if (cats.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Semua'),
              selected: _category == null,
              showCheckmark: false,
              onSelected: (_) => setState(() => _category = null),
            ),
          ),
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(c),
                selected: _category == c,
                showCheckmark: false,
                onSelected: (_) =>
                    setState(() => _category = _category == c ? null : c),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountRow(ColorScheme scheme, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        children: [
          Text(
            '$count produk',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          PopupMenuButton<_Sort>(
            tooltip: 'Urutkan',
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (_) => [
              for (final s in _Sort.values)
                PopupMenuItem(value: s, child: Text(_sortLabels[s]!)),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    _sortLabels[_sort]!,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Product Card ─────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    super.key,
    required this.product,
    required this.price,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final String price;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final int stock = int.tryParse(product.stock.toString()) ?? 0;
    final bool habis = stock <= 0;
    final bool menipis = stock > 0 && stock <= 5;

    final Color badgeColor = habis
        ? scheme.error
        : menipis
        ? Colors.orange.shade800
        : Colors.green.shade700;
    final IconData badgeIcon = habis
        ? Icons.block_rounded
        : menipis
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;
    final String badgeText = habis
        ? 'Stok habis'
        : menipis
        ? 'Sisa $stock'
        : 'Stok $stock';

    final initial = product.name.trim().isEmpty
        ? '?'
        : product.name.trim()[0].toUpperCase();

    return Dismissible(
      key: ValueKey('dismiss_${product.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await onDelete(); // dialog konfirmasi ada di dalam onDelete
        return false; // daftar diperbarui lewat refresh, bukan animasi dismiss
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: scheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_rounded, color: scheme.onError),
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    initial,
                    style: text.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.categoryName,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, size: 14, color: badgeColor),
                                const SizedBox(width: 4),
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opsi',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_rounded),
                        title: Text('Ubah'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: scheme.error,
                        ),
                        title: Text(
                          'Hapus',
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Loading Skeleton ─────────────────────────
class _LoadingList extends StatefulWidget {
  const _LoadingList();

  @override
  State<_LoadingList> createState() => _LoadingListState();
}

class _LoadingListState extends State<_LoadingList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 0.9).animate(_ctrl),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var i = 0; i < 6; i++) ...[
              Container(
                height: 104,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── State Message ─────────────────────────
class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
