import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/recipe_repository.dart';
import '../../../../core/services/recipe_scraper/recipe_scraper_service.dart';
import '../../../../core/services/photo_service.dart';

/// Add/Edit Recipe Screen - supports manual entry, URL import, and image scanning
class AddEditRecipeScreen extends StatefulWidget {
  final Recipe? recipe; // null for add, non-null for edit

  const AddEditRecipeScreen({
    super.key,
    this.recipe,
  });

  @override
  State<AddEditRecipeScreen> createState() => _AddEditRecipeScreenState();
}

class _AddEditRecipeScreenState extends State<AddEditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _photoService = PhotoService();

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _servingsController;
  late TextEditingController _notesController;
  late TextEditingController _sourceUrlController;

  // Data
  final List<Ingredient> _ingredients = [];
  final List<String> _directions = [];
  final List<String> _categories = [];
  final List<String> _photoUrls = [];
  String? _difficulty;
  double? _rating;
  Nutrition? _nutrition;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing recipe data or empty
    final recipe = widget.recipe;
    _titleController = TextEditingController(text: recipe?.title ?? '');
    _descriptionController = TextEditingController(text: recipe?.description ?? '');
    _prepTimeController = TextEditingController(text: recipe?.prepTimeMinutes?.toString() ?? '');
    _cookTimeController = TextEditingController(text: recipe?.cookTimeMinutes?.toString() ?? '');
    _servingsController = TextEditingController(text: recipe?.servings.toString() ?? '4');
    _notesController = TextEditingController(text: recipe?.notes ?? '');
    _sourceUrlController = TextEditingController(text: recipe?.sourceUrl ?? '');

    if (recipe != null) {
      _ingredients.addAll(recipe.ingredients);
      _directions.addAll(recipe.directions);
      _categories.addAll(recipe.categories);
      _photoUrls.addAll(recipe.photoUrls);
      _difficulty = recipe.difficulty;
      _rating = recipe.rating;
      _nutrition = recipe.nutrition;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.recipe != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Recipe' : 'Add Recipe'),
        actions: [
          // Save button
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRecipe,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Import Options (only for new recipes)
            if (!isEditing) ...[
              _buildImportOptionsCard(theme),
              const SizedBox(height: 24),
            ],

            // Basic Info Section
            _buildSectionHeader('Basic Information', Icons.info_outline, theme),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Recipe Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a recipe title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'A brief description of the recipe...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Photos Section
            _buildSectionHeader('Photos', Icons.photo_camera, theme),
            const SizedBox(height: 16),
            _buildPhotosGrid(theme),
            const SizedBox(height: 24),

            // Time & Servings Section
            _buildSectionHeader('Time & Servings', Icons.access_time, theme),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cookTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Cook Time (min)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _servingsController,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _difficulty = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ingredients Section
            _buildSectionHeader('Ingredients', Icons.shopping_basket, theme),
            const SizedBox(height: 16),
            _buildIngredientsList(theme),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: const Text('Add Ingredient'),
            ),
            const SizedBox(height: 24),

            // Directions Section
            _buildSectionHeader('Directions', Icons.list_alt, theme),
            const SizedBox(height: 16),
            _buildDirectionsList(theme),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addDirection,
              icon: const Icon(Icons.add),
              label: const Text('Add Step'),
            ),
            const SizedBox(height: 24),

            // Categories Section
            _buildSectionHeader('Categories', Icons.category, theme),
            const SizedBox(height: 16),
            _buildCategoriesChips(theme),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
            const SizedBox(height: 24),

            // Additional Info
            _buildSectionHeader('Additional Info', Icons.more_horiz, theme),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                hintText: 'Any tips, variations, or notes...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Source URL
            TextFormField(
              controller: _sourceUrlController,
              decoration: const InputDecoration(
                labelText: 'Source URL',
                border: OutlineInputBorder(),
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _saveRecipe,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Update Recipe' : 'Save Recipe'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOptionsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quick Import',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // URL Import Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _importFromUrl,
                icon: const Icon(Icons.link),
                label: const Text('Import from Website URL'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Scan tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'To scan a recipe from a photo, use the scan button at the top of the Recipes screen',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(ThemeData theme) {
    if (_ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No ingredients added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_ingredients.length, (index) {
        final ingredient = _ingredients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(ingredient.name),
            subtitle: Text(
              '${ingredient.quantity ?? ''} ${ingredient.unit ?? ''}'.trim(),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editIngredient(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _ingredients.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDirectionsList(ThemeData theme) {
    if (_directions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No directions added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(_directions.length, (index) {
        final direction = _directions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(direction),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editDirection(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _directions.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCategoriesChips(ThemeData theme) {
    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No categories added yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        return Chip(
          label: Text(category),
          onDeleted: () {
            setState(() {
              _categories.remove(category);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPhotosGrid(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Photo grid or empty state
        if (_photoUrls.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No photos added yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photoUrls.length,
            itemBuilder: (context, index) {
              final photoPath = _photoUrls[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photoPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.outline,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filled(
                      icon: const Icon(Icons.delete, size: 18),
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () => _deletePhoto(index),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addPhotoFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _addPhotoFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Dialog methods
  void _addIngredient() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ingredient Name *',
                  border: OutlineInputBorder(),
                ),
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
                        hintText: 'cups, tsp, etc',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., chopped, diced',
                ),
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
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _ingredients.add(Ingredient(
                    name: nameController.text,
                    quantity: quantityController.text.isNotEmpty
                        ? double.tryParse(quantityController.text)
                        : null,
                    unit: unitController.text.isNotEmpty ? unitController.text : null,
                    notes: notesController.text.isNotEmpty ? notesController.text : null,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editIngredient(int index) {
    final ingredient = _ingredients[index];
    final nameController = TextEditingController(text: ingredient.name);
    final quantityController = TextEditingController(
      text: ingredient.quantity?.toString() ?? '',
    );
    final unitController = TextEditingController(text: ingredient.unit ?? '');
    final notesController = TextEditingController(text: ingredient.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Ingredient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ingredient Name *',
                  border: OutlineInputBorder(),
                ),
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
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
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
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _ingredients[index] = Ingredient(
                    name: nameController.text,
                    quantity: quantityController.text.isNotEmpty
                        ? double.tryParse(quantityController.text)
                        : null,
                    unit: unitController.text.isNotEmpty ? unitController.text : null,
                    notes: notesController.text.isNotEmpty ? notesController.text : null,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addDirection() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Step ${_directions.length + 1}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Direction',
            border: OutlineInputBorder(),
            hintText: 'Describe this step...',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _directions.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editDirection(int index) {
    final controller = TextEditingController(text: _directions[index]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Step ${index + 1}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Direction',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _directions[index] = controller.text;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addCategory() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                hintText: 'e.g., Breakfast, Dessert',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Common categories:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snack', 'Appetizer']
                  .map((cat) => ActionChip(
                        label: Text(cat),
                        onPressed: () {
                          controller.text = cat;
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty &&
                  !_categories.contains(controller.text)) {
                setState(() {
                  _categories.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _importFromUrl() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import from URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Recipe URL',
                border: OutlineInputBorder(),
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ll extract the recipe details from the webpage.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _performUrlImport(controller.text);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }


  // Photo management methods
  Future<void> _addPhotoFromCamera() async {
    final path = await _photoService.pickFromCamera();
    if (path != null) {
      setState(() {
        _photoUrls.add(path);
      });
    }
  }

  Future<void> _addPhotoFromGallery() async {
    final path = await _photoService.pickFromGallery();
    if (path != null) {
      setState(() {
        _photoUrls.add(path);
      });
    }
  }

  Future<void> _deletePhoto(int index) async {
    final photoPath = _photoUrls[index];

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _photoUrls.removeAt(index);
      });

      // Delete the physical file
      await _photoService.deletePhoto(photoPath);
    }
  }

  Future<void> _performUrlImport(String url) async {
    if (url.isEmpty) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Importing recipe...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Use RecipeScraperService to scrape the recipe
      final scraperService = RecipeScraperService();
      final scrapedRecipe = await scraperService.scrapeRecipe(url);

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      if (scrapedRecipe == null) {
        // Failed to scrape recipe
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to import recipe from this URL. Please try entering manually.'),
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Successfully scraped - populate form fields
      setState(() {
        _titleController.text = scrapedRecipe.title;
        _descriptionController.text = scrapedRecipe.description ?? '';
        _prepTimeController.text = scrapedRecipe.prepTimeMinutes?.toString() ?? '';
        _cookTimeController.text = scrapedRecipe.cookTimeMinutes?.toString() ?? '';
        _servingsController.text = scrapedRecipe.servings.toString();
        _notesController.text = scrapedRecipe.notes ?? '';
        _sourceUrlController.text = url;

        // Copy ingredients, directions, categories
        _ingredients.clear();
        _ingredients.addAll(scrapedRecipe.ingredients);

        _directions.clear();
        _directions.addAll(scrapedRecipe.directions);

        _categories.clear();
        _categories.addAll(scrapedRecipe.categories);

        _photoUrls.clear();
        _photoUrls.addAll(scrapedRecipe.photoUrls);

        _difficulty = scrapedRecipe.difficulty;
        _rating = scrapedRecipe.rating;
        _nutrition = scrapedRecipe.nutrition;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported "${scrapedRecipe.title}"!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing recipe: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    if (_directions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one direction')),
      );
      return;
    }

    final recipeRepo = context.read<RecipeRepository>();
    final now = DateTime.now();

    final recipe = Recipe(
      id: widget.recipe?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      ingredients: _ingredients,
      directions: _directions,
      categories: _categories,
      prepTimeMinutes: _prepTimeController.text.isNotEmpty
          ? int.tryParse(_prepTimeController.text)
          : null,
      cookTimeMinutes: _cookTimeController.text.isNotEmpty
          ? int.tryParse(_cookTimeController.text)
          : null,
      servings: int.tryParse(_servingsController.text) ?? 4,
      difficulty: _difficulty,
      rating: _rating,
      photoUrls: _photoUrls,
      sourceUrl: _sourceUrlController.text.isNotEmpty ? _sourceUrlController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      nutrition: _nutrition,
      createdAt: widget.recipe?.createdAt ?? now,
      updatedAt: now,
      isFavorite: widget.recipe?.isFavorite ?? false,
      hasCooked: widget.recipe?.hasCooked ?? false,
    );

    try {
      if (widget.recipe == null) {
        await recipeRepo.insertRecipe(recipe);
      } else {
        await recipeRepo.updateRecipe(recipe);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.recipe == null ? 'Recipe added!' : 'Recipe updated!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving recipe: $e')),
        );
      }
    }
  }
}
