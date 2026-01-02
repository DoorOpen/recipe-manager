import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/grocery_repository.dart';
import '../../../../core/services/grocery_export_service.dart';
import '../widgets/premium_cart_button.dart';

/// Grocery List Detail Screen - shows items in a list with checkboxes
class GroceryListDetailScreen extends StatefulWidget {
  final GroceryList list;

  const GroceryListDetailScreen({
    super.key,
    required this.list,
  });

  @override
  State<GroceryListDetailScreen> createState() => _GroceryListDetailScreenState();
}

class _GroceryListDetailScreenState extends State<GroceryListDetailScreen> {
  final _exportService = GroceryExportService();
  List<GroceryItem> _items = [];
  bool _isLoading = true;
  bool _showCheckedItems = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    final repository = context.read<GroceryRepository>();
    final items = await repository.getItemsForList(widget.list.id);

    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  List<GroceryItem> get _filteredItems {
    if (_showCheckedItems) {
      return _items;
    }
    return _items.where((item) => !item.isChecked).toList();
  }

  Map<GroceryCategory, List<GroceryItem>> get _itemsByCategory {
    final map = <GroceryCategory, List<GroceryItem>>{};
    for (final item in _filteredItems) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showExportDialog(),
            tooltip: 'Export & Share',
          ),
          IconButton(
            icon: Icon(_showCheckedItems ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showCheckedItems = !_showCheckedItems;
              });
            },
            tooltip: _showCheckedItems ? 'Hide checked items' : 'Show checked items',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_checked') {
                _clearCheckedItems();
              } else if (value == 'uncheck_all') {
                _uncheckAllItems();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_checked',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep),
                    SizedBox(width: 8),
                    Text('Clear Checked Items'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'uncheck_all',
                child: Row(
                  children: [
                    Icon(Icons.remove_done),
                    SizedBox(width: 8),
                    Text('Uncheck All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(theme),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_grocery_item_fab',
        onPressed: () => _showAddItemDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_basket,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No items in this list', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Tap + to add items',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final categorizedItems = _itemsByCategory;

    if (categorizedItems.isEmpty && !_showCheckedItems) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            Text('All items checked!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showCheckedItems = true;
                });
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Show checked items'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadItems,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          _buildSummaryCard(theme),
          const SizedBox(height: 16),

          // Items by category
          ...GroceryCategory.values.map((category) {
            final items = categorizedItems[category];
            if (items == null || items.isEmpty) return const SizedBox.shrink();

            return _buildCategorySection(theme, category, items);
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final totalItems = _items.length;
    final checkedItems = _items.where((item) => item.isChecked).length;
    final uncheckedItems = totalItems - checkedItems;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total', totalItems.toString(), theme),
            _buildSummaryItem('Remaining', uncheckedItems.toString(), theme),
            _buildSummaryItem('Checked', checkedItems.toString(), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    ThemeData theme,
    GroceryCategory category,
    List<GroceryItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(_getCategoryIcon(category), size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                _getCategoryName(category),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildItemTile(theme, item)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItemTile(ThemeData theme, GroceryItem item) {
    return Dismissible(
      key: Key(item.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteItem(item),
      child: CheckboxListTile(
        value: item.isChecked,
        onChanged: (value) => _toggleItem(item),
        title: Text(
          '${item.quantity != null && item.quantity! > 0 ? '${item.quantity} ' : ''}${item.unit != null ? '${item.unit} ' : ''}${item.name}',
          style: theme.textTheme.bodyLarge?.copyWith(
            decoration: item.isChecked ? TextDecoration.lineThrough : null,
            color: item.isChecked ? theme.colorScheme.outline : null,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    GroceryCategory selectedCategory = GroceryCategory.other;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                        hintText: 'lbs, oz, etc',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GroceryCategory>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: GroceryCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(_getCategoryIcon(category), size: 20),
                        const SizedBox(width: 12),
                        Text(_getCategoryName(category)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) selectedCategory = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final item = GroceryItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  quantity: quantityController.text.isNotEmpty
                      ? double.tryParse(quantityController.text)
                      : null,
                  unit: unitController.text.isNotEmpty ? unitController.text : null,
                  category: selectedCategory,
                  isChecked: false,
                );

                final repository = context.read<GroceryRepository>();
                await repository.addItem(widget.list.id, item);
                await _loadItems();

                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleItem(GroceryItem item) async {
    final repository = context.read<GroceryRepository>();
    await repository.toggleItemChecked(item.id);
    await _loadItems();
  }

  Future<void> _deleteItem(GroceryItem item) async {
    final repository = context.read<GroceryRepository>();
    await repository.deleteItem(item.id);
    await _loadItems();
  }

  Future<void> _clearCheckedItems() async {
    final repository = context.read<GroceryRepository>();
    await repository.clearCheckedItems(widget.list.id);
    await _loadItems();
  }

  Future<void> _uncheckAllItems() async {
    final repository = context.read<GroceryRepository>();
    for (final item in _items.where((i) => i.isChecked)) {
      await repository.toggleItemChecked(item.id);
    }
    await _loadItems();
  }

  IconData _getCategoryIcon(GroceryCategory category) {
    switch (category) {
      case GroceryCategory.produce:
        return Icons.eco;
      case GroceryCategory.meat:
        return Icons.set_meal;
      case GroceryCategory.dairy:
        return Icons.emoji_food_beverage;
      case GroceryCategory.bakery:
        return Icons.bakery_dining;
      case GroceryCategory.pantry:
        return Icons.kitchen;
      case GroceryCategory.frozen:
        return Icons.ac_unit;
      case GroceryCategory.beverages:
        return Icons.local_drink;
      case GroceryCategory.snacks:
        return Icons.cookie;
      case GroceryCategory.condiments:
        return Icons.opacity;
      case GroceryCategory.spices:
        return Icons.grass;
      case GroceryCategory.other:
        return Icons.shopping_basket;
    }
  }

  String _getCategoryName(GroceryCategory category) {
    switch (category) {
      case GroceryCategory.produce:
        return 'Produce';
      case GroceryCategory.meat:
        return 'Meat & Seafood';
      case GroceryCategory.dairy:
        return 'Dairy & Eggs';
      case GroceryCategory.bakery:
        return 'Bakery';
      case GroceryCategory.pantry:
        return 'Pantry';
      case GroceryCategory.frozen:
        return 'Frozen';
      case GroceryCategory.beverages:
        return 'Beverages';
      case GroceryCategory.snacks:
        return 'Snacks';
      case GroceryCategory.condiments:
        return 'Condiments';
      case GroceryCategory.spices:
        return 'Spices & Herbs';
      case GroceryCategory.other:
        return 'Other';
    }
  }

  /// Show export & share dialog
  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ExportBottomSheet(
        list: widget.list,
        items: _items,
        exportService: _exportService,
      ),
    );
  }
}

/// Bottom sheet for exporting grocery list
class _ExportBottomSheet extends StatelessWidget {
  final GroceryList list;
  final List<GroceryItem> items;
  final GroceryExportService exportService;

  const _ExportBottomSheet({
    required this.list,
    required this.items,
    required this.exportService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uncheckedItems = exportService.getUncheckedItems(items);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Export & Share',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${items.length} items (${uncheckedItems.length} unchecked)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),

          // Share Options
          Text(
            'SHARE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Share as Text'),
            subtitle: const Text('Send via messaging, email, etc.'),
            onTap: () async {
              Navigator.pop(context);
              await exportService.shareAsText(list, items);
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_present),
            title: const Text('Share as CSV'),
            subtitle: const Text('Spreadsheet-compatible format'),
            onTap: () async {
              Navigator.pop(context);
              await exportService.shareAsCsv(list, items);
            },
          ),
          const Divider(),

          // Premium Auto-Cart Feature
          Text(
            'AUTO-CART (PREMIUM)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          PremiumCartButton(
            items: uncheckedItems,
            isPremium: false, // TODO: Get from user subscription status
            retailer: 'walmart',
            onUpgradeRequired: () {
              // TODO: Navigate to upgrade screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upgrade feature coming soon!'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(),

          // Retailer Integrations
          Text(
            'SHOP ONLINE (FREE)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          _buildRetailerTile(
            context,
            ExportFormat.instacart,
            () => exportService.openInstacartWithItems(uncheckedItems),
          ),
          _buildRetailerTile(
            context,
            ExportFormat.walmart,
            () => exportService.openWalmartWithItems(uncheckedItems),
          ),
          _buildRetailerTile(
            context,
            ExportFormat.amazonFresh,
            () => exportService.openAmazonFreshWithItems(uncheckedItems),
          ),
          _buildRetailerTile(
            context,
            ExportFormat.target,
            () => exportService.openRetailerWebsite(ExportFormat.target, list, uncheckedItems),
          ),
          _buildRetailerTile(
            context,
            ExportFormat.kroger,
            () => exportService.openRetailerWebsite(ExportFormat.kroger, list, uncheckedItems),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRetailerTile(
    BuildContext context,
    ExportFormat format,
    Future<bool> Function() onTap,
  ) {
    final info = GroceryExportService.retailerInfo[format]!;
    return ListTile(
      leading: Text(
        info['icon']!,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(info['name']!),
      subtitle: const Text('Opens in browser'),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () async {
        Navigator.pop(context);
        final success = await onTap();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open ${info['name']}'),
            ),
          );
        }
      },
    );
  }
}
