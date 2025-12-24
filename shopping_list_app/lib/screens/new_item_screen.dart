import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_item.dart';

// ジャンル（モデルや他画面と整合性を取るための定数）
const List<String> availableCategories = ['食品', '日用品', '衣類', 'その他'];

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _selectedCategory = availableCategories[0];
  DateTime? _selectedDueDate;
  List<String> _availableLocations = [];
  bool _isLoadingLocations = false;
  String? _selectedLocation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableLocations();
  }

  Future<void> _loadAvailableLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final locations = <String>{};
      final collections = ['shopping_list', 'purchase_records'];
      for (var col in collections) {
        final snapshot = await FirebaseFirestore.instance.collection(col).get();
        for (final doc in snapshot.docs) {
          final loc = doc.data()['location'] as String?;
          if (loc != null && loc.isNotEmpty) locations.add(loc);
        }
      }
      setState(() {
        _availableLocations = locations.toList()..sort();
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocations = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _selectDueDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? firstDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      setState(() => _selectedDueDate = selectedDate);
    }
  }

  void _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newItem = ShoppingItem(
      id: '',
      name: _nameController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 1,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      category: _selectedCategory,
      dueDate: _selectedDueDate,
    );

    Navigator.of(context).pop(newItem);
  }

  InputDecoration _buildInputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white10
          : Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('リストに追加'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              _formKey.currentState!.reset();
              setState(() {
                _nameController.clear();
                _locationController.clear();
                _quantityController.text = '1';
                _selectedCategory = availableCategories[0];
                _selectedDueDate = null;
              });
            },
            child: const Text('リセット', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. 基本情報カード
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                          'アイテム名',
                          icon: Icons.shopping_cart,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'アイテム名を入力してください'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          '個数',
                          icon: Icons.production_quantity_limits,
                        ),
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                            ? '1以上の数値を入力'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 場所・カテゴリカード
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '購入場所・ジャンル',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingLocations)
                        const LinearProgressIndicator()
                      else
                        Autocomplete<String>(
                          optionsBuilder: (textValue) {
                            if (textValue.text.isEmpty)
                              return _availableLocations;
                            return _availableLocations.where(
                              (s) => s.contains(textValue.text),
                            );
                          },
                          onSelected: (s) =>
                              setState(() => _locationController.text = s),
                          fieldViewBuilder: (ctx, ctrl, focus, onSaved) {
                            if (ctrl.text.isEmpty &&
                                _locationController.text.isNotEmpty) {
                              ctrl.text = _locationController.text;
                            }
                            return TextFormField(
                              controller: ctrl,
                              focusNode: focus,
                              decoration: _buildInputDecoration(
                                '場所を選択または入力',
                                icon: Icons.place,
                              ),
                              onChanged: (v) => _locationController.text = v,
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: _buildInputDecoration(
                          'ジャンル',
                          icon: Icons.category,
                        ),
                        items: availableCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategory = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. 期限設定カード
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.calendar_today,
                    color: Colors.blueAccent,
                  ),
                  title: const Text(
                    '購入期限',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _selectedDueDate == null
                        ? '設定なし'
                        : '${_selectedDueDate!.year}/${_selectedDueDate!.month}/${_selectedDueDate!.day}',
                  ),
                  trailing: _selectedDueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _selectedDueDate = null),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _selectDueDate,
                ),
              ),
              const SizedBox(height: 32),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text(
                    'リストに保存する',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
