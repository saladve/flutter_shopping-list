import 'package:flutter/material.dart';
import '../models/shopping_item.dart';

//ジャンル
const List<String> availableCategories = [
  '食品',
  '日用品',
  '衣類',
  'その他',
];

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({super.key});

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  int _enteredQuantity = 1;
  String? _selectedLocation;
  String _selectedCategory = availableCategories[0];

  var _isSaving = false;

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      final newItem = ShoppingItem(
        name: _nameController.text,
        quantity: _enteredQuantity,
        location: _selectedLocation,
        category: _selectedCategory,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.of(context).pop(newItem);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('リストにアイテムを追加'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'アイテム名',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty || value.length > 50) {
                    return '50文字以内のアイテム名を入力してください。';
                  }
                  return null;
                },
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '個数',
                      ),
                      initialValue: _enteredQuantity.toString(), // 初期値は1
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null || int.tryParse(value)! <= 0) {
                          return '有効な個数 (1以上) を入力してください。';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '購入場所 (任意)',
                      ),
                      maxLength: 30,
                      onSaved: (value) {
                        _selectedLocation = value!.trim().isEmpty ? null : value;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('種類: '),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCategory,
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
                ],
              ),

              const SizedBox(height: 24),

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
                      });
                    },
                    child: const Text('リセット'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveItem,
                    child: _isSaving
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}