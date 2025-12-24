import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/purchase_record.dart';

class NewPurchaseRecordScreen extends StatefulWidget {
  final String? initialName;
  final String? initialCategory;

  const NewPurchaseRecordScreen({
    super.key,
    this.initialName,
    this.initialCategory,
  });

  @override
  State<NewPurchaseRecordScreen> createState() =>
      _NewPurchaseRecordScreenState();
}

class _NewPurchaseRecordScreenState extends State<NewPurchaseRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _quantityController;
  late TextEditingController _notesController;
  late TextEditingController _categoryController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  List<String> _availableLocations = [];
  bool _isLoadingLocations = false;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _priceController = TextEditingController();
    _locationController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _notesController = TextEditingController();
    _categoryController = TextEditingController(
      text: widget.initialCategory ?? '',
    );
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _loadAvailableLocations();
  }

  Future<void> _loadAvailableLocations() async {
    setState(() => _isLoadingLocations = true);
    try {
      final locations = <String>{};

      // 買い物リストと購買記録の両方から場所を収集
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
    _priceController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _savePurchaseRecord() {
    if (!_formKey.currentState!.validate()) return;

    final location = _selectedLocation ?? _locationController.text.trim();
    if (location.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('購入場所を入力または選択してください')));
      return;
    }

    final purchaseDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final purchaseRecord = PurchaseRecord(
      id: '',
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0.0,
      location: location,
      purchaseDate: purchaseDateTime,
      quantity: int.tryParse(_quantityController.text) ?? 1,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text,
    );

    Navigator.of(context).pop(purchaseRecord);
  }

  InputDecoration _buildInputDecoration(
    String label, {
    IconData? icon,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
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
      appBar: AppBar(title: const Text('購買記録を追加'), elevation: 0),
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
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: _buildInputDecoration(
                          '商品名',
                          icon: Icons.shopping_bag,
                        ),
                        validator: (v) => v!.isEmpty ? '商品名を入力してください' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _buildInputDecoration(
                                '値段',
                                prefixText: '¥ ',
                              ),
                              validator: (v) =>
                                  (double.tryParse(v ?? '') == null)
                                  ? '数値を入力'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: _buildInputDecoration('個数'),
                            ),
                          ),
                        ],
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
                        '購入場所',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                              setState(() => _selectedLocation = s),
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
                      TextFormField(
                        controller: _categoryController,
                        decoration: _buildInputDecoration(
                          'ジャンル',
                          icon: Icons.category,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. 日時設定カード
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_selectedTime.format(context)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. 備考カード
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _notesController,
                    decoration: _buildInputDecoration('備考（オプション）'),
                    maxLines: 3,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _savePurchaseRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    '記録を保存する',
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
