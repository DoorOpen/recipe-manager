import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/recipe_scan_service.dart';
import '../../../../core/repositories/recipe_repository.dart';
import 'add_edit_recipe_screen.dart';

/// Screen for reviewing and editing scanned recipe before saving
class ScannedRecipeReviewScreen extends StatefulWidget {
  final ScanRecipeResult scanResult;

  const ScannedRecipeReviewScreen({
    super.key,
    required this.scanResult,
  });

  @override
  State<ScannedRecipeReviewScreen> createState() =>
      _ScannedRecipeReviewScreenState();
}

class _ScannedRecipeReviewScreenState
    extends State<ScannedRecipeReviewScreen> {
  bool _isSaving = false;

  Future<void> _saveRecipe() async {
    if (widget.scanResult.recipe == null) return;

    setState(() => _isSaving = true);

    try {
      final repository = context.read<RecipeRepository>();
      await repository.insertRecipe(widget.scanResult.recipe!);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to recipes list (pop twice to skip scan screen)
      Navigator.of(context).pop(); // Pop review screen
      Navigator.of(context).pop(); // Pop scan screen
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save recipe: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editBeforeSaving() async {
    if (widget.scanResult.recipe == null) return;

    // Navigate to add/edit screen with scanned recipe
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecipeScreen(
          recipe: widget.scanResult.recipe,
        ),
      ),
    );

    if (result == true && mounted) {
      // Recipe was saved from edit screen
      Navigator.of(context).pop(); // Pop review screen
      Navigator.of(context).pop(); // Pop scan screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.scanResult.recipe;
    final metadata = widget.scanResult.metadata;
    final validation = widget.scanResult.validation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Scanned Recipe'),
        actions: [
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editBeforeSaving,
              tooltip: 'Edit before saving',
            ),
        ],
      ),
      body: recipe == null
          ? _buildErrorState()
          : Column(
              children: [
                // Validation warnings
                if (validation != null && validation.warnings.isNotEmpty)
                  _buildValidationWarnings(validation.warnings),

                // Recipe preview
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI scan badge
                        _buildAIBadge(metadata),

                        const SizedBox(height: 16),

                        // Recipe title
                        Text(
                          recipe.title,
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),

                        const SizedBox(height: 8),

                        // Description
                        if (recipe.description != null &&
                            recipe.description!.isNotEmpty)
                          Text(
                            recipe.description!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Recipe info
                        _buildRecipeInfo(recipe),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Ingredients
                        _buildSectionHeader('Ingredients'),
                        const SizedBox(height: 12),
                        ...recipe.ingredients.map(
                          (ing) => _buildIngredientItem(ing),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),

                        // Directions
                        _buildSectionHeader('Instructions'),
                        const SizedBox(height: 12),
                        ...recipe.directions.asMap().entries.map(
                              (entry) => _buildDirectionItem(
                                entry.key + 1,
                                entry.value,
                              ),
                            ),

                        // Categories
                        if (recipe.categories.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Categories'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recipe.categories.map((cat) {
                              return Chip(
                                label: Text(cat),
                                backgroundColor: Colors.blue.shade50,
                              );
                            }).toList(),
                          ),
                        ],

                        // Notes
                        if (recipe.notes != null && recipe.notes!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Notes'),
                          const SizedBox(height: 12),
                          Text(recipe.notes!),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                _buildActionButtons(),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to scan recipe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              widget.scanResult.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationWarnings(List<String> warnings) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Warnings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map((warning) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '• $warning',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAIBadge(ScanMetadata? metadata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          const Text(
            'AI Scanned',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (metadata != null) ...[
            const SizedBox(width: 8),
            Text(
              '\$${metadata.cost.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeInfo(recipe) {
    return Row(
      children: [
        if (recipe.servings > 0)
          _buildInfoChip(
            Icons.people,
            '${recipe.servings} servings',
          ),
        if (recipe.prepTimeMinutes > 0)
          _buildInfoChip(
            Icons.schedule,
            '${recipe.prepTimeMinutes} min prep',
          ),
        if (recipe.cookTimeMinutes > 0)
          _buildInfoChip(
            Icons.timer,
            '${recipe.cookTimeMinutes} min cook',
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildIngredientItem(ingredient) {
    String quantityText = '';
    if (ingredient.quantity != null && ingredient.quantity! > 0) {
      quantityText = '${ingredient.quantity} ';
    }
    if (ingredient.unit.isNotEmpty) {
      quantityText += '${ingredient.unit} ';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  if (quantityText.isNotEmpty)
                    TextSpan(
                      text: quantityText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  TextSpan(text: ingredient.name),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionItem(int step, String direction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                direction,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveRecipe,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Recipe',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Edit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _editBeforeSaving,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Before Saving'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
