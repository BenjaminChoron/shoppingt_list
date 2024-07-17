import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shopping_list/data/categories.dart';
import 'dart:convert';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  final List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  void _loadItems() async {
    final url = Uri.https(
        dotenv.env['FIREBASE_ENDPOINT'] as String, 'grocery_items.json');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Failed to load items... Please try again later.';
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> extractedData = json.decode(response.body);

    final List<GroceryItem> loadedItems = [];

    for (final item in extractedData.entries) {
      final category = categories.entries.firstWhere(
        (element) => element.value.title == item.value['category'],
      );

      loadedItems.add(GroceryItem(
        id: item.key,
        name: item.value['name'],
        quantity: item.value['quantity'],
        category: category.value,
      ));
    }

    setState(() {
      _groceryItems.clear();
      _groceryItems.addAll(loadedItems);
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const NewItem()),
    );

    if (newItem == null) {
      return;
    }

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) {
    setState(() {
      _groceryItems.remove(item);
    });
  }

  @override
  void initState() {
    _loadItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 36,
            ),
          ),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      body: SafeArea(child: content),
    );
  }
}
