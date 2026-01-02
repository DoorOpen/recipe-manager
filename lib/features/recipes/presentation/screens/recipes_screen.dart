import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/repositories/recipe_repository.dart';
import '../providers/recipe_list_provider.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'add_edit_recipe_screen.dart';
import 'recipe_scan_screen.dart';

// Export SortOption so it's accessible in this file
export '../providers/recipe_list_provider.dart' show SortOption;

/// Recipes screen - displays list of all recipes
class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecipeListProvider(
        context.read<RecipeRepository>(),
      ),
      child: const _RecipesScreenContent(),
    );
  }
}

class _RecipesScreenContent extends StatelessWidget {
  const _RecipesScreenContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RecipeListProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          // Scan Recipe Button
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecipeScanScreen(),
                ),
              );
              // Refresh list if recipe was scanned and saved
              if (result == true && context.mounted) {
                context.read<RecipeListProvider>().refresh();
              }
            },
            tooltip: 'Scan Recipe',
          ),

          // Search Button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),

          // Sort Button
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortBottomSheet(context),
          ),

          // Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),

          // Favorites Toggle
          IconButton(
            icon: Icon(
              provider.showFavoritesOnly
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: provider.showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: () {
              context.read<RecipeListProvider>().toggleFavoritesOnly();
            },
          ),
        ],
      ),
      body: _buildBody(context, provider, theme),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recipes_list_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditRecipeScreen(),
            ),
          );
          // Refresh list if recipe was added
          if (result == true && context.mounted) {
            context.read<RecipeListProvider>().refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Recipe'),
      ),
    );
  }

  /// Build main body content based on state
  Widget _buildBody(
    BuildContext context,
    RecipeListProvider provider,
    ThemeData theme,
  ) {
    // Loading State
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error State
    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading recipes',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
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

    // Empty State
    if (provider.recipes.isEmpty) {
      return _buildEmptyState(context, provider, theme);
    }

    // Success State - Display Recipes
    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: Column(
        children: [
          // Active Filters Chip Bar
          if (provider.searchQuery.isNotEmpty ||
              provider.selectedCategory != null ||
              provider.selectedDifficulty != null ||
              provider.minRating != null)
            _buildActiveFiltersBar(context, provider),

          // Recipe List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.recipes.length,
              itemBuilder: (context, index) {
                final recipe = provider.recipes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RecipeCard(
                    recipe: recipe,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                    onFavoriteToggle: () {
                      provider.toggleFavorite(recipe.id);
                    },
                    onDelete: () {
                      provider.deleteRecipe(recipe.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${recipe.title} deleted'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              // TODO: Implement undo functionality
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state UI
  Widget _buildEmptyState(
    BuildContext context,
    RecipeListProvider provider,
    ThemeData theme,
  ) {
    final hasActiveFilters = provider.searchQuery.isNotEmpty ||
        provider.selectedCategory != null ||
        provider.selectedDifficulty != null ||
        provider.minRating != null ||
        provider.showFavoritesOnly;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasActiveFilters ? Icons.search_off : Icons.restaurant_menu,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasActiveFilters ? 'No recipes found' : 'No recipes yet',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Tap + to add your first recipe',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
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

  /// Build active filters chip bar
  Widget _buildActiveFiltersBar(
    BuildContext context,
    RecipeListProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Search Query Chip
                if (provider.searchQuery.isNotEmpty)
                  Chip(
                    label: Text('Search: "${provider.searchQuery}"'),
                    onDeleted: () {
                      context.read<RecipeListProvider>().searchRecipes('');
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),

                // Category Filter Chip
                if (provider.selectedCategory != null)
                  Chip(
                    label: Text('Category: ${provider.selectedCategory}'),
                    onDeleted: () {
                      context.read<RecipeListProvider>().filterByCategory(null);
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),

                // Difficulty Filter Chip
                if (provider.selectedDifficulty != null)
                  Chip(
                    label: Text('Difficulty: ${provider.selectedDifficulty}'),
                    onDeleted: () {
                      context.read<RecipeListProvider>().filterByDifficulty(null);
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),

                // Rating Filter Chip
                if (provider.minRating != null)
                  Chip(
                    label: Text('Rating: ${provider.minRating}+ ⭐'),
                    onDeleted: () {
                      context.read<RecipeListProvider>().filterByRating(null);
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
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

  /// Show search dialog
  void _showSearchDialog(BuildContext context) {
    final provider = context.read<RecipeListProvider>();
    final controller = TextEditingController(text: provider.searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Recipes'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter recipe name or ingredient...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            provider.searchRecipes(value.trim());
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
              provider.searchRecipes(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    final provider = context.read<RecipeListProvider>();

    // Define available categories
    final categories = [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Dessert',
      'Snack',
      'Appetizer',
      'Side Dish',
      'Salad',
      'Soup',
      'Beverage',
      'Baking',
      'Quick & Easy',
      'Asian',
      'Italian',
      'Mexican',
      'American',
    ];

    final difficulties = ['Easy', 'Medium', 'Hard'];
    final ratings = [1.0, 2.0, 3.0, 4.0, 4.5, 5.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        provider.clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Filter Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Category Section
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: provider.selectedCategory == category,
                            onSelected: (selected) {
                              provider.filterByCategory(selected ? category : null);
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    // Difficulty Section
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Difficulty',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: difficulties.map((difficulty) {
                          return FilterChip(
                            label: Text(difficulty),
                            selected: provider.selectedDifficulty == difficulty,
                            onSelected: (selected) {
                              provider.filterByDifficulty(selected ? difficulty : null);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),

                    // Rating Section
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Minimum Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ratings.map((rating) {
                          return FilterChip(
                            label: Text('$rating ⭐'),
                            selected: provider.minRating == rating,
                            onSelected: (selected) {
                              provider.filterByRating(selected ? rating : null);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Apply Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show sort bottom sheet
  void _showSortBottomSheet(BuildContext context) {
    final provider = context.read<RecipeListProvider>();

    final sortOptions = {
      SortOption.nameAsc: 'Name (A-Z)',
      SortOption.nameDesc: 'Name (Z-A)',
      SortOption.ratingDesc: 'Rating (High to Low)',
      SortOption.ratingAsc: 'Rating (Low to High)',
      SortOption.timeAsc: 'Time (Shortest First)',
      SortOption.timeDesc: 'Time (Longest First)',
    };

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Sort Options
            ...sortOptions.entries.map((entry) {
              return RadioListTile<SortOption>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: provider.sortOption,
                onChanged: (value) {
                  if (value != null) {
                    provider.setSortOption(value);
                    Navigator.pop(context);
                  }
                },
              );
            }),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
