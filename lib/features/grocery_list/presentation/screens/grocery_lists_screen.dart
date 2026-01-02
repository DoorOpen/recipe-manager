import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/grocery_repository.dart';
import '../providers/grocery_list_provider.dart';
import 'grocery_list_detail_screen.dart';

/// Grocery Lists screen - displays all shopping lists
class GroceryListsScreen extends StatelessWidget {
  const GroceryListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GroceryListProvider(
        context.read<GroceryRepository>(),
      ),
      child: const _GroceryListsContent(),
    );
  }
}

class _GroceryListsContent extends StatelessWidget {
  const _GroceryListsContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GroceryListProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: _buildBody(context, provider, theme),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'grocery_list_fab',
        onPressed: () => _showCreateListDialog(context, provider),
        icon: const Icon(Icons.add),
        label: const Text('New List'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GroceryListProvider provider,
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
            Text('Error loading lists', style: theme.textTheme.titleLarge),
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

    if (provider.lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('No shopping lists', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first list',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.lists.length,
        itemBuilder: (context, index) {
          final list = provider.lists[index];
          return _buildListCard(context, provider, theme, list);
        },
      ),
    );
  }

  Widget _buildListCard(
    BuildContext context,
    GroceryListProvider provider,
    ThemeData theme,
    GroceryList list,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.shopping_cart,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          list.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Created ${dateFormat.format(list.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog(context, provider, list);
            } else if (value == 'rename') {
              _showRenameDialog(context, provider, list);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroceryListDetailScreen(list: list),
            ),
          ).then((_) => provider.refresh());
        },
      ),
    );
  }

  void _showCreateListDialog(BuildContext context, GroceryListProvider provider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Shopping List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'e.g., Weekly Groceries',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              provider.createList(value);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createList(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    GroceryListProvider provider,
    GroceryList list,
  ) {
    final controller = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'List Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await context.read<GroceryRepository>().updateListName(
                      list.id,
                      controller.text,
                    );
                await provider.refresh();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    GroceryListProvider provider,
    GroceryList list,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text('Are you sure you want to delete "${list.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteList(list.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
