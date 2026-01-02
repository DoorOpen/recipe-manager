import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/repositories/pantry_repository.dart';
import '../../../../core/repositories/recipe_repository.dart';
import '../../../../core/models/models.dart' as models;
import '../../../recipes/presentation/screens/recipe_detail_screen.dart';

/// Screen showing recipes that can be made with available pantry items
class WhatCanIMakeScreen extends StatefulWidget {
  const WhatCanIMakeScreen({super.key});

  @override
  State<WhatCanIMakeScreen> createState() => _WhatCanIMakeScreenState();
}

class _WhatCanIMakeScreenState extends State<WhatCanIMakeScreen> {
  List<models.Recipe> _matchingRecipes = [];
  List<models.PantryItem> _pantryItems = [];
  bool _isLoading = true;
  int _minMatchPercentage = 50;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pantryRepo = context.read<PantryRepository>();
      final recipeRepo = context.read<RecipeRepository>();

      _pantryItems = await pantryRepo.getAllItems();
      final allRecipes = await recipeRepo.getAllRecipes();

      // Find recipes that match pantry items
      _matchingRecipes = _findMatchingRecipes(allRecipes, _pantryItems);
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<models.Recipe> _findMatchingRecipes(
    List<models.Recipe> recipes,
    List<models.PantryItem> pantryItems,
  ) {
    final pantryNames = pantryItems.map((item) => item.name.toLowerCase()).toSet();
    final matchedRecipes = <({models.Recipe recipe, int matchCount, int totalIngredients})>[];

    for (final recipe in recipes) {
      if (recipe.ingredients.isEmpty) continue;

      int matchCount = 0;
      for (final ingredient in recipe.ingredients) {
        final ingredientName = ingredient.name.toLowerCase();

        // Check for exact match or partial match
        if (pantryNames.any((pantryItem) =>
            pantryItem.contains(ingredientName) ||
            ingredientName.contains(pantryItem))) {
          matchCount++;
        }
      }

      // Calculate match percentage
      final matchPercentage = (matchCount / recipe.ingredients.length * 100).round();

      if (matchPercentage >= _minMatchPercentage) {
        matchedRecipes.add((
          recipe: recipe,
          matchCount: matchCount,
          totalIngredients: recipe.ingredients.length,
        ));
      }
    }

    // Sort by match percentage (highest first)
    matchedRecipes.sort((a, b) {
      final aPercentage = (a.matchCount / a.totalIngredients * 100).round();
      final bPercentage = (b.matchCount / b.totalIngredients * 100).round();
      return bPercentage.compareTo(aPercentage);
    });

    return matchedRecipes.map((r) => r.recipe).toList();
  }

  int _getMatchCount(models.Recipe recipe) {
    final pantryNames = _pantryItems.map((item) => item.name.toLowerCase()).toSet();
    int count = 0;

    for (final ingredient in recipe.ingredients) {
      final ingredientName = ingredient.name.toLowerCase();
      if (pantryNames.any((pantryItem) =>
          pantryItem.contains(ingredientName) ||
          ingredientName.contains(pantryItem))) {
        count++;
      }
    }

    return count;
  }

  int _getMatchPercentage(models.Recipe recipe) {
    if (recipe.ingredients.isEmpty) return 0;
    final matchCount = _getMatchCount(recipe);
    return (matchCount / recipe.ingredients.length * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('What Can I Make?'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter by match percentage
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Minimum Match: $_minMatchPercentage%',
                            style: theme.textTheme.titleSmall,
                          ),
                          const Spacer(),
                          Text(
                            '${_matchingRecipes.length} recipes',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _minMatchPercentage.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 10,
                        label: '$_minMatchPercentage%',
                        onChanged: (value) {
                          setState(() {
                            _minMatchPercentage = value.round();
                            _matchingRecipes = _findMatchingRecipes(
                              context.read<RecipeRepository>().getAllRecipes() as List<models.Recipe>,
                              _pantryItems,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Recipe list
                Expanded(
                  child: _matchingRecipes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 80,
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No recipes found',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adding more items to your pantry\nor lowering the match percentage',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _matchingRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = _matchingRecipes[index];
                            final matchCount = _getMatchCount(recipe);
                            final totalIngredients = recipe.ingredients.length;
                            final matchPercentage = _getMatchPercentage(recipe);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: matchPercentage == 100
                                      ? Colors.green.withOpacity(0.1)
                                      : matchPercentage >= 75
                                          ? Colors.blue.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                  child: Text(
                                    '$matchPercentage%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: matchPercentage == 100
                                          ? Colors.green
                                          : matchPercentage >= 75
                                              ? Colors.blue
                                              : Colors.orange,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  recipe.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Have $matchCount of $totalIngredients ingredients',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    if (matchCount < totalIngredients) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Missing ${totalIngredients - matchCount} ingredient${totalIngredients - matchCount > 1 ? 's' : ''}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RecipeDetailScreen(recipe: recipe),
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
}
