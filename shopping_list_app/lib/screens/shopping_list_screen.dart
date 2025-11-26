import 'package:flutter/material.dart';
import '../models/shopping_item.dart';
import '../screens/new_item_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
// ダミーデータ
  final List<ShoppingItem> _shoppingList = [
    const ShoppingItem(name: '牛乳', quantity: 1, isCompleted: false),
    const ShoppingItem(name: 'パン', quantity: 2, isCompleted: true),
    const ShoppingItem(name: '卵'),
    const ShoppingItem(name: 'トマト'),
  ];

  // チェックボックスの状態を切り替えるメソッド
  void _toggleCompletion(int index) {
    setState(() {
      final currentItem = _shoppingList[index];

      _shoppingList[index] = currentItem.copyWith(
        isCompleted: !currentItem.isCompleted,
      );
    });
  }

  void _addItem(BuildContext context) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => const NewItemScreen(),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _shoppingList.add(
        ShoppingItem(
          name: result, // NewItemScreenから返されたアイテム名を使用
          quantity: 1, // 新規追加アイテムのデフォルト数量
          isCompleted: false,
        ),
      );
    });
  }

  @override //UI
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('買い物メモ'),
        backgroundColor: Theme.of(context).primaryColor,
      ),

      body: ListView.builder(
        itemCount: _shoppingList.length,
        itemBuilder: (context, index) {
          final item = _shoppingList[index];

          return ListTile(
            title: Text(
              item.name,
              style: TextStyle(
                decoration: item.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: item.isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Text('数量: ${item.quantity}'),
            leading: Checkbox(
              value: item.isCompleted,
              onChanged: (bool? newValue) {
                _toggleCompletion(index);
              },
            ),
            onTap: () {
              _toggleCompletion(index);
            },
          );
        },
      ),

      // 追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addItem(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}