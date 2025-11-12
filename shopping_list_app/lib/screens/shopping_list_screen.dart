import 'package:flutter/material.dart';
import '../models/shopping_item.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  // Stateオブジェクトを作成するメソッド
  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
//ダミーデータ
  final List<ShoppingItem> _shoppingList = [
    const ShoppingItem(name: '牛乳', quantity: 1, isCompleted: false),
    const ShoppingItem(name: 'パン', quantity: 2, isCompleted: true),
    const ShoppingItem(name: '卵'),
    const ShoppingItem(name: 'トマト'),
  ];

  // チェックボックスの状態を切り替えるメソッド（次のステップで利用）
  void _toggleCompletion(int index) {
    // setStateブロック内でデータを変更すると、UIが自動的に再描画されます
    setState(() {
      final currentItem = _shoppingList[index];

      _shoppingList[index] = currentItem.copyWith(
        isCompleted: !currentItem.isCompleted,
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

      // 画面右下のフローティングアクションボタン（アイテム追加用）
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _shoppingList.add(
              ShoppingItem(
                name: '新規アイテム ${DateTime.now().second}', // 時刻でユニークな名前に
                quantity: 1,
              ),
            );
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}