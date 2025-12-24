import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_item.dart';

//ジャンル
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

  int _enteredQuantity = 1;
  String? _selectedLocation;
  String _selectedCategory = availableCategories[0];
  DateTime? _selectedDueDate;
  List<String> _availableLocations = [];
  bool _isLoadingLocations = false;

  var _isSaving = false;

  @override
  void initState() {
    super.initState();
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

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      final newItem = ShoppingItem(
        id: '',
        name: _nameController.text,
        quantity: _enteredQuantity,
        location: _selectedLocation?.isNotEmpty == true
            ? _selectedLocation
            : null,
        category: _selectedCategory,
        dueDate: _selectedDueDate,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(newItem);
    }
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
      setState(() {
        _selectedDueDate = selectedDate;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('リストにアイテムを追加')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // アイテム名
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'アイテム名',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          maxLength: 50,
                          decoration: InputDecoration(
                            hintText: '例: 牛乳',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            counterText: '',
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty ||
                                value.length > 50) {
                              return '50文字以内のアイテム名を入力してください。';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 個数と購入場所
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '個数と場所',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: '個数',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                initialValue: _enteredQuantity.toString(),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null ||
                                      int.tryParse(value) == null ||
                                      int.tryParse(value)! <= 0) {
                                    return '有効な個数を入力してください。';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredQuantity = int.parse(value!);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '購入場所 (任意)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Autocomplete を使うことで「入力」と「リスト選択」を統合
                                  Autocomplete<String>(
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                          // 入力がないときは候補を表示しない、または全リストを表示する
                                          if (textEditingValue.text == '') {
                                            return _availableLocations;
                                          }
                                          // 入力文字に一致する候補をフィルタリング
                                          return _availableLocations.where((
                                            String option,
                                          ) {
                                            return option.contains(
                                              textEditingValue.text,
                                            );
                                          });
                                        },
                                    // 選択された時の処理
                                    onSelected: (String selection) {
                                      setState(() {
                                        _selectedLocation = selection;
                                        _locationController.text = selection;
                                      });
                                    },
                                    // 入力フィールド自体の見た目
                                    fieldViewBuilder:
                                        (
                                          context,
                                          controller,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          // 既存の _locationController と同期させるための処理
                                          return TextFormField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            decoration: InputDecoration(
                                              hintText: '選択または新規入力',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                              // 入力中にクリアできるアイコンを置くと便利
                                              suffixIcon:
                                                  controller.text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                        Icons.clear,
                                                        size: 18,
                                                      ),
                                                      onPressed: () {
                                                        controller.clear();
                                                        setState(
                                                          () =>
                                                              _selectedLocation =
                                                                  null,
                                                        );
                                                      },
                                                    )
                                                  : null,
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedLocation =
                                                    value.trim().isEmpty
                                                    ? null
                                                    : value.trim();
                                                _locationController.text =
                                                    value; // 外部保存用コントローラと同期
                                              });
                                            },
                                          );
                                        },
                                    // 候補リストの見た目（Notion風に少しカスタマイズ）
                                    optionsViewBuilder:
                                        (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 4.0,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                width:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.4, // 幅を調整
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 200,
                                                    ),
                                                child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  itemCount: options.length,
                                                  itemBuilder:
                                                      (
                                                        BuildContext context,
                                                        int index,
                                                      ) {
                                                        final String option =
                                                            options.elementAt(
                                                              index,
                                                            );
                                                        return ListTile(
                                                          title: Text(option),
                                                          onTap: () =>
                                                              onSelected(
                                                                option,
                                                              ),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ジャンルと期限
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ジャンルと期限',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // ジャンル
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            underline: const SizedBox(),
                            isExpanded: true,
                            items: availableCategories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 期限
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(
                              _selectedDueDate == null
                                  ? '期限を設定'
                                  : '${_selectedDueDate!.year}年${_selectedDueDate!.month}月${_selectedDueDate!.day}日',
                            ),
                            trailing: _selectedDueDate != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedDueDate = null;
                                      });
                                    },
                                  )
                                : null,
                            onTap: _selectDueDate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _formKey.currentState!.reset();
                        setState(() {
                          _enteredQuantity = 1;
                          _selectedCategory = availableCategories[0];
                          _selectedLocation = null;
                          _selectedDueDate = null;
                        });
                      },
                      child: const Text('リセット'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveItem,
                      icon: _isSaving
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('保存'),
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
