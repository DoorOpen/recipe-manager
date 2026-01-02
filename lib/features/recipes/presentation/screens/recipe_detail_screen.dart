import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/recipe_repository.dart';
import '../../../../core/repositories/meal_plan_repository.dart';
import '../../../../core/repositories/grocery_repository.dart';
import 'add_edit_recipe_screen.dart';
import 'cooking_mode_screen.dart';

/// Recipe Detail Screen - displays full recipe information
class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe;
  final Set<int> _checkedIngredients = {};
  final Set<int> _checkedSteps = {};
  double _servingsMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
  }

  int get _scaledServings => (_recipe.servings * _servingsMultiplier).round();

  double _scaleQuantity(double? quantity) {
    if (quantity == null) return 0;
    return quantity * _servingsMultiplier;
  }

  String _formatQuantity(double quantity) {
    // Format to avoid unnecessary decimals
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    // Check for common fractions
    if ((quantity * 2).roundToDouble() == quantity * 2) {
      // Half values: 0.5, 1.5, 2.5, etc.
      final whole = quantity.floor();
      if (whole == 0) {
        return '½';
      } else {
        return '$whole½';
      }
    }
    if ((quantity * 3).roundToDouble() == quantity * 3) {
      // Third values
      final whole = quantity.floor();
      final remainder = quantity - whole;
      if (remainder > 0.6) {
        return whole == 0 ? '⅔' : '$whole⅔';
      } else if (remainder > 0.2) {
        return whole == 0 ? '⅓' : '$whole⅓';
      }
    }
    if ((quantity * 4).roundToDouble() == quantity * 4) {
      // Quarter values
      final whole = quantity.floor();
      final remainder = quantity - whole;
      if (remainder > 0.7) {
        return whole == 0 ? '¾' : '$whole¾';
      } else if (remainder > 0.2) {
        return whole == 0 ? '¼' : '$whole¼';
      }
    }
    // Default to 1 decimal place
    return quantity.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipeRepo = context.read<RecipeRepository>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: _buildHeroImage(),
            ),
            actions: [
              // Favorite Button
              IconButton(
                icon: Icon(
                  _recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _recipe.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () async {
                  await recipeRepo.toggleFavorite(_recipe.id);
                  setState(() {
                    _recipe = _recipe.copyWith(isFavorite: !_recipe.isFavorite);
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _recipe.isFavorite
                              ? 'Added to favorites'
                              : 'Removed from favorites',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              // More Actions Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) => _handleMenuAction(value, context, recipeRepo),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit Recipe'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share Recipe'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'addToMealPlan',
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today),
                        SizedBox(width: 8),
                        Text('Add to Meal Plan'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'addToGroceryList',
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart),
                        SizedBox(width: 8),
                        Text('Add to Grocery List'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete Recipe', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Recipe Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe Metadata
                  _buildMetadata(theme),
                  const SizedBox(height: 24),

                  // Description
                  if (_recipe.description != null && _recipe.description!.isNotEmpty) ...[
                    Text(
                      _recipe.description!,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quick Info Chips
                  _buildQuickInfoChips(theme),
                  const SizedBox(height: 24),

                  // Ingredients Section
                  _buildSectionHeader('Ingredients', Icons.shopping_basket, theme),
                  const SizedBox(height: 12),
                  _buildIngredientsList(theme),
                  const SizedBox(height: 32),

                  // Directions Section
                  _buildSectionHeader('Directions', Icons.list_alt, theme),
                  const SizedBox(height: 12),
                  _buildDirectionsList(theme),
                  const SizedBox(height: 32),

                  // Nutrition Section (if available)
                  if (_recipe.nutrition != null) ...[
                    _buildSectionHeader('Nutrition Information', Icons.pie_chart, theme),
                    const SizedBox(height: 12),
                    _buildNutritionInfo(theme),
                    const SizedBox(height: 32),
                  ],

                  // Notes Section (if available)
                  if (_recipe.notes != null && _recipe.notes!.isNotEmpty) ...[
                    _buildSectionHeader('Notes', Icons.note, theme),
                    const SizedBox(height: 12),
                    Text(
                      _recipe.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Source URL (if available)
                  if (_recipe.sourceUrl != null && _recipe.sourceUrl!.isNotEmpty) ...[
                    Text(
                      'Source',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening ${_recipe.sourceUrl}')),
                        );
                      },
                      child: Text(
                        _recipe.sourceUrl!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'recipe_detail_fab', // Unique tag to avoid Hero conflicts
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CookingModeScreen(recipe: _recipe),
            ),
          );
        },
        icon: const Icon(Icons.restaurant),
        label: const Text('Start Cooking'),
      ),
    );
  }

  Widget _buildHeroImage() {
    if (_recipe.photoUrls.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _recipe.photoUrls.first,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
          ),
          // Gradient overlay for better text visibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(
        Icons.restaurant,
        size: 80,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildMetadata(ThemeData theme) {
    return Row(
      children: [
        // Rating
        if (_recipe.rating != null) ...[
          Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(
            _recipe.rating!.toStringAsFixed(1),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
        ],
        // Difficulty
        if (_recipe.difficulty != null) ...[
          Icon(Icons.bar_chart, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            _recipe.difficulty!,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
        ],
        // Has Cooked Badge
        if (_recipe.hasCooked)
          Chip(
            label: const Text('Cooked', style: TextStyle(fontSize: 12)),
            backgroundColor: Colors.green[100],
            avatar: const Icon(Icons.check_circle, size: 16),
          ),
      ],
    );
  }

  Widget _buildQuickInfoChips(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_recipe.prepTimeMinutes != null)
          _buildInfoChip(
            icon: Icons.schedule,
            label: 'Prep: ${_recipe.prepTimeMinutes} min',
            theme: theme,
          ),
        if (_recipe.cookTimeMinutes != null)
          _buildInfoChip(
            icon: Icons.timer,
            label: 'Cook: ${_recipe.cookTimeMinutes} min',
            theme: theme,
          ),
        // Servings with scaling controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant, size: 18),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: _servingsMultiplier > 0.5
                    ? () {
                        setState(() {
                          _servingsMultiplier -= 0.5;
                        });
                      }
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                'Serves: $_scaledServings',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: _servingsMultiplier < 5.0
                    ? () {
                        setState(() {
                          _servingsMultiplier += 0.5;
                        });
                      }
                    : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (_recipe.categories.isNotEmpty)
          ..._recipe.categories.map(
            (category) => Chip(
              label: Text(category, style: const TextStyle(fontSize: 12)),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(ThemeData theme) {
    return Column(
      children: List.generate(_recipe.ingredients.length, (index) {
        final ingredient = _recipe.ingredients[index];
        final isChecked = _checkedIngredients.contains(index);

        return CheckboxListTile(
          value: isChecked,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _checkedIngredients.add(index);
              } else {
                _checkedIngredients.remove(index);
              }
            });
          },
          title: InkWell(
            onTap: () => _checkForLinkedRecipe(ingredient.name),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${ingredient.quantity != null ? _formatQuantity(_scaleQuantity(ingredient.quantity)) : ''} ${ingredient.unit ?? ''} ${ingredient.name}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? theme.colorScheme.outline : null,
                    ),
                  ),
                ),
                FutureBuilder<bool>(
                  future: _hasLinkedRecipe(ingredient.name),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return Icon(
                        Icons.link,
                        size: 16,
                        color: theme.colorScheme.primary,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          subtitle: ingredient.notes != null
              ? Text(ingredient.notes!, style: theme.textTheme.bodySmall)
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      }),
    );
  }

  /// Check if ingredient name matches any recipe title
  Future<bool> _hasLinkedRecipe(String ingredientName) async {
    final recipeRepo = context.read<RecipeRepository>();
    final recipes = await recipeRepo.searchRecipes(ingredientName);
    return recipes.any((r) =>
      r.title.toLowerCase().contains(ingredientName.toLowerCase()) &&
      r.id != _recipe.id
    );
  }

  /// Check for and navigate to linked recipe
  Future<void> _checkForLinkedRecipe(String ingredientName) async {
    final recipeRepo = context.read<RecipeRepository>();
    final recipes = await recipeRepo.searchRecipes(ingredientName);

    if (!mounted) return;

    // Find exact or close matches (excluding current recipe)
    final matches = recipes.where((r) =>
      r.title.toLowerCase().contains(ingredientName.toLowerCase()) &&
      r.id != _recipe.id
    ).toList();

    if (matches.isEmpty) return;

    if (matches.length == 1) {
      // Direct navigation if only one match
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeDetailScreen(recipe: matches.first),
        ),
      );
    } else {
      // Show selection dialog if multiple matches
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Recipe'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final recipe = matches[index];
                return ListTile(
                  leading: const Icon(Icons.restaurant),
                  title: Text(recipe.title),
                  subtitle: recipe.description != null
                    ? Text(
                        recipe.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDirectionsList(ThemeData theme) {
    return Column(
      children: List.generate(_recipe.directions.length, (index) {
        final direction = _recipe.directions[index];
        final isChecked = _checkedSteps.contains(index);
        final stepNumber = index + 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Number Circle
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _checkedSteps.remove(index);
                    } else {
                      _checkedSteps.add(index);
                    }
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isChecked
                        ? Icon(Icons.check, color: theme.colorScheme.onPrimary, size: 16)
                        : Text(
                            '$stepNumber',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Direction Text
              Expanded(
                child: Text(
                  direction,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                    color: isChecked ? theme.colorScheme.outline : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNutritionInfo(ThemeData theme) {
    final nutrition = _recipe.nutrition!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (nutrition.calories != null)
              _buildNutritionRow('Calories', '${nutrition.calories} kcal', theme),
            if (nutrition.protein != null)
              _buildNutritionRow('Protein', '${nutrition.protein}g', theme),
            if (nutrition.carbs != null)
              _buildNutritionRow('Carbs', '${nutrition.carbs}g', theme),
            if (nutrition.fat != null)
              _buildNutritionRow('Fat', '${nutrition.fat}g', theme),
            if (nutrition.fiber != null)
              _buildNutritionRow('Fiber', '${nutrition.fiber}g', theme),
            if (nutrition.sodium != null)
              _buildNutritionRow('Sodium', '${nutrition.sodium}mg', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, BuildContext context, RecipeRepository recipeRepo) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditRecipeScreen(recipe: _recipe),
          ),
        ).then((updated) {
          // Reload recipe if it was updated
          if (updated == true && context.mounted) {
            recipeRepo.getRecipeById(_recipe.id).then((updatedRecipe) {
              if (updatedRecipe != null && mounted) {
                setState(() {
                  _recipe = updatedRecipe;
                });
              }
            });
          }
        });
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share recipe coming soon!')),
        );
        break;
      case 'addToMealPlan':
        _showAddToMealPlanDialog(context, recipeRepo);
        break;
      case 'addToGroceryList':
        _showAddToGroceryListDialog(context);
        break;
      case 'delete':
        _confirmDelete(context, recipeRepo);
        break;
    }
  }

  void _confirmDelete(BuildContext context, RecipeRepository recipeRepo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${_recipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await recipeRepo.deleteRecipe(_recipe.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${_recipe.title} deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddToMealPlanDialog(BuildContext context, RecipeRepository recipeRepo) {
    DateTime selectedDate = DateTime.now();
    MealType selectedMealType = MealType.dinner;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add to Meal Plan'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)),
                subtitle: const Text('Date'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),

              // Meal Type Selector
              DropdownButtonFormField<MealType>(
                value: selectedMealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                ),
                items: MealType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getMealTypeIcon(type), size: 20),
                        const SizedBox(width: 12),
                        Text(_getMealTypeName(type)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedMealType = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final mealPlanRepo = context.read<MealPlanRepository>();

              final entry = MealPlanEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                date: selectedDate,
                mealType: selectedMealType,
                recipeId: _recipe.id,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await mealPlanRepo.insertEntry(entry);

              if (mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${_recipe.title}" to meal plan!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.breakfast_dining;
      case MealType.lunch:
        return Icons.lunch_dining;
      case MealType.dinner:
        return Icons.dinner_dining;
      case MealType.snack:
        return Icons.cookie;
    }
  }

  String _getMealTypeName(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  void _showAddToGroceryListDialog(BuildContext context) async {
    final groceryRepo = context.read<GroceryRepository>();
    final lists = await groceryRepo.getAllLists();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add to Grocery List'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No grocery lists available. Create one below.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return ListTile(
                        leading: const Icon(Icons.shopping_basket),
                        title: Text(list.name),
                        onTap: () async {
                          await _addIngredientsToList(list.id, groceryRepo);
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added ingredients to "${list.name}"'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              const Divider(height: 24),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showCreateListDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New List'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Grocery List'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            border: OutlineInputBorder(),
            hintText: 'e.g., Weekly Shopping',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final groceryRepo = context.read<GroceryRepository>();
                final listId = await groceryRepo.createList(nameController.text);
                await _addIngredientsToList(listId, groceryRepo);

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Created "${nameController.text}" and added ingredients'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addIngredientsToList(String listId, GroceryRepository groceryRepo) async {
    for (final ingredient in _recipe.ingredients) {
      final groceryItem = GroceryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + ingredient.name.hashCode.toString(),
        name: ingredient.name,
        quantity: ingredient.quantity != null ? _scaleQuantity(ingredient.quantity) : null,
        unit: ingredient.unit,
        category: _categorizeIngredient(ingredient.name),
        isChecked: false,
      );

      await groceryRepo.addItem(listId, groceryItem);
    }
  }

  GroceryCategory _categorizeIngredient(String name) {
    final nameLower = name.toLowerCase();

    // Produce
    if (nameLower.contains('tomato') || nameLower.contains('lettuce') ||
        nameLower.contains('onion') || nameLower.contains('garlic') ||
        nameLower.contains('carrot') || nameLower.contains('celery') ||
        nameLower.contains('pepper') || nameLower.contains('potato') ||
        nameLower.contains('spinach') || nameLower.contains('broccoli') ||
        nameLower.contains('cucumber') || nameLower.contains('apple') ||
        nameLower.contains('banana') || nameLower.contains('orange') ||
        nameLower.contains('lemon') || nameLower.contains('lime')) {
      return GroceryCategory.produce;
    }

    // Meat & Seafood
    if (nameLower.contains('chicken') || nameLower.contains('beef') ||
        nameLower.contains('pork') || nameLower.contains('turkey') ||
        nameLower.contains('fish') || nameLower.contains('salmon') ||
        nameLower.contains('shrimp') || nameLower.contains('lamb') ||
        nameLower.contains('bacon') || nameLower.contains('sausage')) {
      return GroceryCategory.meat;
    }

    // Dairy & Eggs
    if (nameLower.contains('milk') || nameLower.contains('cheese') ||
        nameLower.contains('yogurt') || nameLower.contains('cream') ||
        nameLower.contains('butter') || nameLower.contains('egg')) {
      return GroceryCategory.dairy;
    }

    // Bakery
    if (nameLower.contains('bread') || nameLower.contains('roll') ||
        nameLower.contains('bagel') || nameLower.contains('tortilla') ||
        nameLower.contains('pita') || nameLower.contains('croissant')) {
      return GroceryCategory.bakery;
    }

    // Pantry
    if (nameLower.contains('rice') || nameLower.contains('pasta') ||
        nameLower.contains('flour') || nameLower.contains('sugar') ||
        nameLower.contains('oil') || nameLower.contains('vinegar') ||
        nameLower.contains('bean') || nameLower.contains('lentil')) {
      return GroceryCategory.pantry;
    }

    // Frozen
    if (nameLower.contains('frozen') || nameLower.contains('ice cream')) {
      return GroceryCategory.frozen;
    }

    // Beverages
    if (nameLower.contains('juice') || nameLower.contains('soda') ||
        nameLower.contains('coffee') || nameLower.contains('tea') ||
        nameLower.contains('water') || nameLower.contains('wine') ||
        nameLower.contains('beer')) {
      return GroceryCategory.beverages;
    }

    // Snacks
    if (nameLower.contains('chip') || nameLower.contains('cookie') ||
        nameLower.contains('cracker') || nameLower.contains('popcorn')) {
      return GroceryCategory.snacks;
    }

    // Condiments
    if (nameLower.contains('sauce') || nameLower.contains('ketchup') ||
        nameLower.contains('mustard') || nameLower.contains('mayo') ||
        nameLower.contains('salsa') || nameLower.contains('dressing')) {
      return GroceryCategory.condiments;
    }

    // Spices & Herbs
    if (nameLower.contains('spice') || nameLower.contains('herb') ||
        nameLower.contains('oregano') || nameLower.contains('basil') ||
        nameLower.contains('thyme') || nameLower.contains('rosemary') ||
        nameLower.contains('cumin') || nameLower.contains('paprika') ||
        nameLower.contains('cinnamon') || nameLower.contains('pepper') ||
        nameLower.contains('salt')) {
      return GroceryCategory.spices;
    }

    return GroceryCategory.other;
  }
}
