import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/repositories/pantry_repository.dart';
import '../../../../core/models/models.dart' as models;
import '../../../../shared/theme/app_theme.dart';
import '../providers/pantry_provider.dart';
import 'add_edit_pantry_item_screen.dart';
import 'what_can_i_make_screen.dart';

/// Pantry screen - displays pantry inventory
class PantryScreen extends StatelessWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PantryProvider(context.read<PantryRepository>()),
      child: const _PantryScreenContent(),
    );
  }
}

class _PantryScreenContent extends StatelessWidget {
  const _PantryScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        actions: [
          // Search
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),

          // Filter
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterMenu(context),
          ),

          // What can I make?
          IconButton(
            icon: const Icon(Icons.restaurant),
            tooltip: 'What can I make?',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WhatCanIMakeScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(context, provider, theme),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pantry_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPantryItemScreen(),
            ),
          );
          if (result == true && context.mounted) {
            context.read<PantryProvider>().refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PantryProvider provider,
    ThemeData theme,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading items', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(provider.error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.items.isEmpty) {
      return _buildEmptyState(context, provider, theme);
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Column(
        children: [
          // Active filters bar
          if (provider.selectedLocation != null ||
              provider.searchQuery.isNotEmpty ||
              provider.showExpiredOnly ||
              provider.showExpiringSoonOnly)
            _buildActiveFiltersBar(context, provider),

          // Items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                return _buildPantryItemCard(context, item, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    PantryProvider provider,
    ThemeData theme,
  ) {
    final hasActiveFilters = provider.selectedLocation != null ||
        provider.searchQuery.isNotEmpty ||
        provider.showExpiredOnly ||
        provider.showExpiringSoonOnly;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasActiveFilters ? Icons.search_off : Icons.kitchen,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters ? 'No items found' : 'Pantry is empty',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Add items to track your inventory',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.clearFilters(),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFiltersBar(
    BuildContext context,
    PantryProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (provider.searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: "${provider.searchQuery}"'),
                    onDeleted: () => provider.searchItems(''),
                  ),
                if (provider.selectedLocation != null)
                  Chip(
                    label: Text(provider.selectedLocation!.displayName),
                    onDeleted: () => provider.filterByLocation(null),
                  ),
                if (provider.showExpiredOnly)
                  Chip(
                    label: const Text('Expired'),
                    onDeleted: () => provider.toggleExpiredOnly(),
                  ),
                if (provider.showExpiringSoonOnly)
                  Chip(
                    label: const Text('Expiring Soon'),
                    onDeleted: () => provider.toggleExpiringSoonOnly(),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => provider.clearFilters(),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryItemCard(
    BuildContext context,
    models.PantryItem item,
    PantryProvider provider,
  ) {
    final theme = Theme.of(context);
    final bool isExpired = item.isExpired;
    final bool isExpiringSoon = item.isExpiringSoon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isExpired
              ? AppTheme.errorColor.withOpacity(0.1)
              : isExpiringSoon
                  ? AppTheme.warningColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getLocationIcon(item.location),
            color: isExpired
                ? AppTheme.errorColor
                : isExpiringSoon
                    ? AppTheme.warningColor
                    : AppTheme.primaryColor,
          ),
        ),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (item.quantity != null)
              Text(
                '${_formatQuantity(item.quantity!)} ${item.unit ?? ''}',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 2),
            Text(
              item.location.displayName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            if (item.expirationDate != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 14,
                    color: isExpired
                        ? AppTheme.errorColor
                        : isExpiringSoon
                            ? AppTheme.warningColor
                            : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Expires: ${_formatDate(item.expirationDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isExpired
                          ? AppTheme.errorColor
                          : isExpiringSoon
                              ? AppTheme.warningColor
                              : AppTheme.textSecondary,
                      fontWeight: isExpired || isExpiringSoon
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditPantryItemScreen(item: item),
                ),
              );
              if (result == true && context.mounted) {
                provider.refresh();
              }
            } else if (value == 'delete') {
              _confirmDelete(context, item, provider);
            }
          },
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditPantryItemScreen(item: item),
            ),
          );
          if (result == true && context.mounted) {
            provider.refresh();
          }
        },
      ),
    );
  }

  IconData _getLocationIcon(models.PantryLocation location) {
    switch (location) {
      case models.PantryLocation.pantry:
        return Icons.kitchen;
      case models.PantryLocation.refrigerator:
        return Icons.kitchen;
      case models.PantryLocation.freezer:
        return Icons.ac_unit;
      case models.PantryLocation.spiceRack:
        return Icons.set_meal;
      case models.PantryLocation.other:
        return Icons.inventory_2;
    }
  }

  String _formatQuantity(double quantity) {
    if (quantity % 1 == 0) {
      return quantity.toInt().toString();
    }
    return quantity.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showSearchDialog(BuildContext context) {
    final provider = context.read<PantryProvider>();
    final controller = TextEditingController(text: provider.searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Pantry'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter item name...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            provider.searchItems(value.trim());
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.searchItems(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    final provider = context.read<PantryProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Filter by',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Expired Items'),
              trailing: provider.showExpiredOnly
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                provider.toggleExpiredOnly();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Expiring Soon'),
              trailing: provider.showExpiringSoonOnly
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                provider.toggleExpiringSoonOnly();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...models.PantryLocation.values.map((location) {
              return ListTile(
                leading: Icon(_getLocationIcon(location)),
                title: Text(location.displayName),
                trailing: provider.selectedLocation == location
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  provider.filterByLocation(location);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    models.PantryItem item,
    PantryProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteItem(item.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.name} deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
