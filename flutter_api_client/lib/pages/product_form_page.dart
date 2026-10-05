import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;

  List<Category> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = true;
  bool _categoryFailed = false;

  bool get _isEdit => widget.product != null;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    _descCtrl = TextEditingController(text: widget.product?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _stockCtrl = TextEditingController(
      text: widget.product?.stock.toString() ?? '',
    );
    _selectedCategoryId = widget.product?.categoryId;
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _loadingCategories = true;
      _categoryFailed = false;
    });
    try {
      final cats = await _api.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loadingCategories = false;
        // Hindari error dropdown jika kategori lama tidak ada di daftar.
        if (!cats.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCategories = false;
        _categoryFailed = true;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  String _rupiah(int number) {
    final digits = number.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }

  void _stepStock(int delta) {
    final current = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    _stockCtrl.text = next.toString();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final product = Product(
      id: widget.product?.id ?? 0,
      categoryId: _selectedCategoryId!,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: int.parse(_priceCtrl.text.trim()),
      stock: int.parse(_stockCtrl.text.trim()),
    );

    try {
      if (_isEdit) {
        await _api.updateProduct(product.id, product);
      } else {
        await _api.createProduct(product);
      }
      if (mounted) {
        _snack(_isEdit ? 'Perubahan disimpan' : 'Produk ditambahkan');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('Gagal menyimpan: $e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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
          backgroundColor: error ? scheme.error : Colors.green.shade700,
          content: Text(msg),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final priceValue = int.tryParse(_priceCtrl.text.trim());

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Ubah produk' : 'Tambah produk',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Informasi produk ──
                _Section(
                  icon: Icons.inventory_2_outlined,
                  title: 'Informasi produk',
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(
                        label: 'Nama produk',
                        icon: Icons.label_outline_rounded,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama produk wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryField(scheme),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      maxLength: 160,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _dec(
                        label: 'Deskripsi',
                        hint: 'Ceritakan singkat tentang produk ini',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Harga & stok ──
                _Section(
                  icon: Icons.sell_outlined,
                  title: 'Harga dan stok',
                  children: [
                    TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      decoration: _dec(
                        label: 'Harga',
                        hint: '2850000',
                        prefixText: 'Rp  ',
                        helper: priceValue == null
                            ? 'Tulis angka saja, tanpa titik'
                            : _rupiah(priceValue),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null) return 'Masukkan harga dalam angka';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec(label: 'Stok', hint: '0').copyWith(
                        prefixIcon: IconButton(
                          tooltip: 'Kurangi stok',
                          icon: const Icon(Icons.remove_rounded),
                          onPressed: () => _stepStock(-1),
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Tambah stok',
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () => _stepStock(1),
                        ),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null) return 'Masukkan jumlah stok';
                        return null;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest,
            border: Border(
              top: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
            ),
          ),
          child: FilledButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : Icon(_isEdit ? Icons.check_rounded : Icons.add_rounded),
            label: Text(
              _loading
                  ? 'Menyimpan...'
                  : (_isEdit ? 'Simpan perubahan' : 'Tambah produk'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField(ColorScheme scheme) {
    if (_categoryFailed) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: scheme.error, size: 20),
            const SizedBox(width: 10),
            const Expanded(child: Text('Kategori gagal dimuat')),
            TextButton(
              onPressed: _fetchCategories,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _selectedCategoryId,
      isExpanded: true,
      borderRadius: BorderRadius.circular(16),
      decoration: _dec(
        label: 'Kategori',
        hint: _loadingCategories ? 'Memuat kategori...' : 'Pilih kategori',
        icon: Icons.category_outlined,
      ),
      items: _categories
          .map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name)))
          .toList(),
      onChanged: _loadingCategories
          ? null
          : (val) => setState(() => _selectedCategoryId = val),
      validator: (v) => v == null ? 'Pilih salah satu kategori' : null,
    );
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    String? helper,
    String? prefixText,
    IconData? icon,
    bool alignLabelWithHint = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      helperStyle: TextStyle(
        color: scheme.primary,
        fontWeight: FontWeight.w600,
      ),
      prefixText: prefixText,
      prefixIcon: icon == null ? null : Icon(icon),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(scheme.primary, 2),
      errorBorder: border(scheme.error),
      focusedErrorBorder: border(scheme.error, 2),
    );
  }
}

// ───────────────────────── Section ─────────────────────────
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
