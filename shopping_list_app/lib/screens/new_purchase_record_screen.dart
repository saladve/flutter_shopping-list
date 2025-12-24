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
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final locations = <String>{};

      // 買い物リストから場所を取得
      final shoppingListSnapshot = await FirebaseFirestore.instance
          .collection('shopping_list')
          .get();

      for (final doc in shoppingListSnapshot.docs) {
        final data = doc.data();
        final location = data['location'] as String?;
        if (location != null && location.isNotEmpty) {
          locations.add(location);
        }
      }

      // 購買記録からも場所を取得
      final purchaseRecordsSnapshot = await FirebaseFirestore.instance
          .collection('purchase_records')
          .get();

      for (final doc in purchaseRecordsSnapshot.docs) {
        final data = doc.data();
        final location = data['location'] as String?;
        if (location != null && location.isNotEmpty) {
          locations.add(location);
        }
      }

      setState(() {
        _availableLocations = locations.toList()..sort();
        _isLoadingLocations = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
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
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _savePurchaseRecord() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('商品名を入力してください')));
      return;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('価格を入力してください')));
      return;
    }

    if (_selectedLocation?.isEmpty != false &&
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('購入場所を入力してください')));
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
      name: _nameController.text,
      price: double.parse(_priceController.text),
      location: _selectedLocation?.isNotEmpty == true
          ? _selectedLocation!
          : _locationController.text,
      purchaseDate: purchaseDateTime,
      quantity: int.parse(_quantityController.text),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      category: _categoryController.text.isNotEmpty
          ? _categoryController.text
          : null,
    );

    Navigator.of(context).pop(purchaseRecord);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('購買記録を追加'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '商品名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '値段',
                border: OutlineInputBorder(),
                prefixText: '¥ ',
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '購入場所',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                if (_isLoadingLocations)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Autocomplete<String>(
                    // 1. 既存リストから候補を表示するロジック
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _availableLocations;
                      }
                      return _availableLocations.where((String option) {
                        return option.contains(textEditingValue.text);
                      });
                    },

                    // 2. 候補から選ばれた時の処理
                    onSelected: (String selection) {
                      setState(() {
                        _selectedLocation = selection;
                        _locationController.text = selection;
                      });
                    },

                    // 3. 入力ボックス自体の見た目
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          // 初期値をコントローラーに反映させるための処理
                          if (controller.text != _locationController.text) {
                            controller.text = _locationController.text;
                          }

                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: '選択または新規入力',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              // 入力内容を消去するボタン（任意）
                              suffixIcon: controller.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        controller.clear();
                                        _locationController.clear();
                                        setState(
                                          () => _selectedLocation = null,
                                        );
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _locationController.text = value; // 外部保存用と同期
                                _selectedLocation = value.isEmpty
                                    ? null
                                    : value;
                              });
                            },
                          );
                        },

                    // 4. 候補リスト（ドロップダウン部分）のカスタマイズ
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(8),
                          // ここの幅は適宜調整してください
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48,
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'ジャンル（オプション）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '個数',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectDate,
                    child: Text(
                      '購入日: ${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectTime,
                    child: Text(
                      '時刻: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '備考（オプション）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _savePurchaseRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: const Text(
                '保存',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
