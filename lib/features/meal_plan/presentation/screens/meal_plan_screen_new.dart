import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/models.dart';
import '../../../../core/repositories/meal_plan_repository.dart';
import '../../../../core/repositories/recipe_repository.dart';
import '../../../../core/repositories/grocery_repository.dart';
import '../../../../core/repositories/pantry_repository.dart';
import '../../../recipes/presentation/screens/recipe_detail_screen.dart';
import '../providers/meal_plan_provider.dart';

/// Meal Plan screen - displays weekly calendar with planned meals
class MealPlanScreenNew extends StatelessWidget {
  const MealPlanScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MealPlanProvider(
        context.read<MealPlanRepository>(),
        context.read<RecipeRepository>(),
      ),
      child: const _MealPlanContent(),
    );
  }
}

class _MealPlanContent extends StatelessWidget {
  const _MealPlanContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealPlanProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => _showGenerateGroceryListDialog(context, provider),
            tooltip: 'Generate Shopping List',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => provider.goToToday(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Week Navigation Header
          _buildWeekNavigationHeader(context, provider, theme),

          // Loading or Content
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildWeekView(context, provider, theme),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'meal_plan_fab',
        onPressed: () => _showAddMealDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeekNavigationHeader(
    BuildContext context,
    MealPlanProvider provider,
    ThemeData theme,
  ) {
    final weekStart = provider.weekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));

    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.previousWeek(),
          ),
          Expanded(
            child: Text(
              '${startFormat.format(weekStart)} - ${endFormat.format(weekEnd)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.nextWeek(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    MealPlanProvider provider,
    ThemeData theme,
  ) {
    final weekDates = provider.weekDates;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: weekDates.length,
        itemBuilder: (context, index) {
          final date = weekDates[index];
          final entries = provider.getEntriesForDate(date);
          final isToday = _isToday(date);
          final isSelected = _isSameDay(date, provider.selectedDate);

          return _buildDayCard(
            context,
            provider,
            theme,
            date,
            entries,
            isToday: isToday,
            isSelected: isSelected,
          );
        },
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    MealPlanProvider provider,
    ThemeData theme,
    DateTime date,
    List<MealPlanEntry> entries, {
    required bool isToday,
    required bool isSelected,
  }) {
    final dayFormat = DateFormat('EEEE');
    final dateFormat = DateFormat('MMMM d');

    // Group entries by meal type
    final entriesByType = <MealType, List<MealPlanEntry>>{};
    for (final entry in entries) {
      entriesByType.putIfAbsent(entry.mealType, () => []).add(entry);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 4 : 1,
      color: isToday
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: InkWell(
        onTap: () {
          provider.selectDate(date);
          _showAddMealDialog(context, provider, preselectedDate: date);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayFormat.format(date),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isToday ? theme.colorScheme.primary : null,
                          ),
                        ),
                        Text(
                          dateFormat.format(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Today',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Meals
              if (entries.isEmpty)
                Text(
                  'No meals planned',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ..._buildMealEntries(
                  context,
                  provider,
                  theme,
                  date,
                  entriesByType,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildMealEntries(
    BuildContext context,
    MealPlanProvider provider,
    ThemeData theme,
    DateTime date,
    Map<MealType, List<MealPlanEntry>> entriesByType,
  ) {
    final widgets = <Widget>[];

    // Order: Breakfast, Lunch, Dinner, Snack
    final mealOrder = [
      MealType.breakfast,
      MealType.lunch,
      MealType.dinner,
      MealType.snack,
    ];

    for (final mealType in mealOrder) {
      final entries = entriesByType[mealType];
      if (entries == null || entries.isEmpty) continue;

      widgets.add(const SizedBox(height: 8));
      widgets.add(_buildMealTypeSection(
        context,
        provider,
        theme,
        date,
        mealType,
        entries,
      ));
    }

    return widgets;
  }

  Widget _buildMealTypeSection(
    BuildContext context,
    MealPlanProvider provider,
    ThemeData theme,
    DateTime date,
    MealType mealType,
    List<MealPlanEntry> entries,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meal Type Header
        Row(
          children: [
            Icon(
              _getMealTypeIcon(mealType),
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _getMealTypeName(mealType),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Meal Entries
        ...entries.map((entry) => Padding(
          padding: const EdgeInsets.only(left: 24, top: 4),
          child: _buildMealEntry(context, provider, theme, date, entry),
        )),
      ],
    );
  }

  Widget _buildMealEntry(
    BuildContext context,
    MealPlanProvider provider,
    ThemeData theme,
    DateTime date,
    MealPlanEntry entry,
  ) {
    if (entry.recipeId != null) {
      final recipe = provider.getRecipe(entry.recipeId!);

      return InkWell(
        onTap: () {
          if (recipe != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(recipe: recipe),
              ),
            );
          }
        },
        onLongPress: () => _showDeleteEntryDialog(context, provider, entry, date),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  recipe?.title ?? 'Loading recipe...',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (recipe != null) ...[
                if (recipe.prepTimeMinutes != null || recipe.cookTimeMinutes != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${(recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)} min',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      );
    } else {
      // Custom note entry
      return InkWell(
        onLongPress: () => _showDeleteEntryDialog(context, provider, entry, date),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            entry.customNote ?? 'No description',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
  }

  void _showAddMealDialog(
    BuildContext context,
    MealPlanProvider provider, {
    DateTime? preselectedDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddMealDialog(
        provider: provider,
        preselectedDate: preselectedDate ?? provider.selectedDate,
      ),
    );
  }

  void _showDeleteEntryDialog(
    BuildContext context,
    MealPlanProvider provider,
    MealPlanEntry entry,
    DateTime date,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: const Text('Are you sure you want to delete this meal plan entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.deleteEntry(entry.id, date);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete'),
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// ============================================================================
// Add Meal Dialog
// ============================================================================

class _AddMealDialog extends StatefulWidget {
  final MealPlanProvider provider;
  final DateTime preselectedDate;

  const _AddMealDialog({
    required this.provider,
    required this.preselectedDate,
  });

  @override
  State<_AddMealDialog> createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<_AddMealDialog> {
  late DateTime _selectedDate;
  MealType _selectedMealType = MealType.dinner;
  final _customNoteController = TextEditingController();
  final _servingsController = TextEditingController();
  Recipe? _selectedRecipe;
  List<Recipe> _allRecipes = [];
  bool _isLoadingRecipes = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.preselectedDate;
    _loadRecipes();
  }

  @override
  void dispose() {
    _customNoteController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    final recipeRepo = context.read<RecipeRepository>();
    final recipes = await recipeRepo.getAllRecipes();
    setState(() {
      _allRecipes = recipes;
      _isLoadingRecipes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Add Meal to Plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Date Selector
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),

            // Meal Type Selector
            DropdownButtonFormField<MealType>(
              value: _selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
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
                    _selectedMealType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Recipe or Custom Note Tabs
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Recipe'),
                      Tab(text: 'Custom Note'),
                    ],
                  ),
                  SizedBox(
                    height: 200,
                    child: TabBarView(
                      children: [
                        // Recipe Tab
                        _buildRecipeSelector(theme),

                        // Custom Note Tab
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: TextField(
                            controller: _customNoteController,
                            decoration: const InputDecoration(
                              labelText: 'Note',
                              border: OutlineInputBorder(),
                              hintText: 'e.g., Dinner out, Leftovers',
                            ),
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Servings Input (only shown when recipe is selected)
            if (_selectedRecipe != null)
              TextField(
                controller: _servingsController,
                decoration: InputDecoration(
                  labelText: 'Servings',
                  border: const OutlineInputBorder(),
                  hintText: 'How many servings?',
                  helperText: 'Recipe default: ${_selectedRecipe!.servings}',
                  prefixIcon: const Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
              ),
            if (_selectedRecipe != null) const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _addMeal,
                    child: const Text('Add Meal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeSelector(ThemeData theme) {
    if (_isLoadingRecipes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allRecipes.isEmpty) {
      return Center(
        child: Text(
          'No recipes yet. Add recipes first!',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: _allRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _allRecipes[index];
        final isSelected = _selectedRecipe?.id == recipe.id;

        return RadioListTile<Recipe>(
          value: recipe,
          groupValue: _selectedRecipe,
          onChanged: (value) {
            setState(() {
              _selectedRecipe = value;
              // Auto-fill servings with recipe default
              if (value != null) {
                _servingsController.text = value.servings.toString();
              }
            });
          },
          title: Text(recipe.title),
          subtitle: recipe.categories.isNotEmpty
              ? Text(recipe.categories.join(', '))
              : null,
          selected: isSelected,
        );
      },
    );
  }

  Future<void> _addMeal() async {
    if (_selectedRecipe == null && _customNoteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a recipe or enter a note')),
      );
      return;
    }

    // Parse servings input
    int? servings;
    if (_selectedRecipe != null && _servingsController.text.isNotEmpty) {
      servings = int.tryParse(_servingsController.text);
    }

    await widget.provider.addEntry(
      date: _selectedDate,
      mealType: _selectedMealType,
      recipeId: _selectedRecipe?.id,
      customNote: _customNoteController.text.isNotEmpty
          ? _customNoteController.text
          : null,
      servings: servings,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal added to plan!')),
      );
    }
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
}

/// Show dialog to generate grocery list from meal plan
void _showGenerateGroceryListDialog(
  BuildContext context,
  MealPlanProvider provider,
) {
  showDialog(
    context: context,
    builder: (dialogContext) => _GenerateGroceryListDialog(
      provider: provider,
    ),
  );
}

/// Dialog to configure and generate a grocery list from meal plan
class _GenerateGroceryListDialog extends StatefulWidget {
  final MealPlanProvider provider;

  const _GenerateGroceryListDialog({required this.provider});

  @override
  State<_GenerateGroceryListDialog> createState() => _GenerateGroceryListDialogState();
}

class _GenerateGroceryListDialogState extends State<_GenerateGroceryListDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGenerating = false;
  String _listName = '';
  bool _excludePantryItems = true; // Default to checking pantry

  @override
  void initState() {
    super.initState();
    // Default to current week
    _startDate = widget.provider.weekStart;
    _endDate = widget.provider.weekStart.add(const Duration(days: 6));
    _listName = 'Week of ${DateFormat('MMM d').format(_startDate!)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Generate Shopping List'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a grocery list from your planned meals',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),

            // List name
            TextField(
              decoration: const InputDecoration(
                labelText: 'List Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              controller: TextEditingController(text: _listName)
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: _listName.length),
                ),
              onChanged: (value) => _listName = value,
            ),
            const SizedBox(height: 16),

            // Date range
            Text(
              'Date Range',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                'From: ${DateFormat('MMM d, yyyy').format(_startDate!)}',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate!,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                    // Update list name
                    _listName = 'Week of ${DateFormat('MMM d').format(_startDate!)}';
                  });
                }
              },
            ),

            // End date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(
                'To: ${DateFormat('MMM d, yyyy').format(_endDate!)}',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate!,
                  firstDate: _startDate!,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
            ),

            const SizedBox(height: 16),

            // Quick date range buttons
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('This Week'),
                  selected: _isCurrentWeek(),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _startDate = widget.provider.weekStart;
                        _endDate = widget.provider.weekStart.add(const Duration(days: 6));
                        _listName = 'Week of ${DateFormat('MMM d').format(_startDate!)}';
                      });
                    }
                  },
                ),
                FilterChip(
                  label: const Text('Next Week'),
                  selected: false,
                  onSelected: (selected) {
                    if (selected) {
                      final nextWeekStart = widget.provider.weekStart.add(const Duration(days: 7));
                      setState(() {
                        _startDate = nextWeekStart;
                        _endDate = nextWeekStart.add(const Duration(days: 6));
                        _listName = 'Week of ${DateFormat('MMM d').format(_startDate!)}';
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pantry Integration Option
            CheckboxListTile(
              value: _excludePantryItems,
              onChanged: (value) {
                setState(() {
                  _excludePantryItems = value ?? true;
                });
              },
              title: const Text('Exclude items in pantry'),
              subtitle: const Text(
                'Check pantry inventory and skip items you already have',
                style: TextStyle(fontSize: 12),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isGenerating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isGenerating ? null : _generateGroceryList,
          child: _isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }

  bool _isCurrentWeek() {
    return _startDate == widget.provider.weekStart &&
        _endDate == widget.provider.weekStart.add(const Duration(days: 6));
  }

  Future<void> _generateGroceryList() async {
    if (_listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Get all meal plan entries in date range
      final mealPlanRepo = context.read<MealPlanRepository>();
      final recipeRepo = context.read<RecipeRepository>();
      final groceryRepo = context.read<GroceryRepository>();
      final pantryRepo = context.read<PantryRepository>();

      final entries = await mealPlanRepo.getEntriesForRange(
        _startDate!,
        _endDate!,
      );

      // Filter entries with recipes
      final entriesWithRecipes = entries.where((e) => e.recipeId != null).toList();

      if (entriesWithRecipes.isEmpty) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No recipes found in selected date range'),
            ),
          );
        }
        return;
      }

      // Fetch all recipes and extract ingredients
      // NOTE: Process each meal plan entry individually to count duplicate recipes
      final ingredientsMap = <String, _MergedIngredient>{};

      for (final entry in entriesWithRecipes) {
        final recipe = await recipeRepo.getRecipeById(entry.recipeId!);
        if (recipe != null) {
          // Calculate serving multiplier
          // If entry has custom servings, use that; otherwise use recipe default
          final targetServings = entry.servings ?? recipe.servings;
          final servingMultiplier = targetServings / recipe.servings;

          for (final ingredient in recipe.ingredients) {
            _mergeIngredient(ingredientsMap, ingredient, recipe.id, servingMultiplier);
          }
        }
      }

      // Get pantry items if exclusion is enabled
      List<PantryItem> pantryItems = [];
      if (_excludePantryItems) {
        pantryItems = await pantryRepo.getAllItems();
      }

      // Create grocery list
      await groceryRepo.createList(_listName);
      final lists = await groceryRepo.getAllLists();
      final createdList = lists.firstWhere((l) => l.name == _listName);

      // Add items to grocery list (with pantry checking)
      int excludedCount = 0;
      int reducedCount = 0;

      for (final merged in ingredientsMap.values) {
        double? finalQuantity = merged.quantity;

        // Check pantry if option is enabled
        if (_excludePantryItems && pantryItems.isNotEmpty) {
          final pantryMatch = _findPantryMatch(merged.name, pantryItems);

          if (pantryMatch != null) {
            // Found matching item in pantry
            final pantryQty = pantryMatch.quantity ?? 0;
            final neededQty = merged.quantity ?? 0;

            if (pantryQty >= neededQty && neededQty > 0) {
              // We have enough in pantry - skip this item
              excludedCount++;
              continue;
            } else if (pantryQty > 0 && neededQty > pantryQty) {
              // We have some, but need more
              finalQuantity = neededQty - pantryQty;
              reducedCount++;
            }
          }
        }

        // Add item to grocery list
        final item = GroceryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + merged.name.hashCode.toString(),
          name: merged.name,
          quantity: finalQuantity,
          unit: merged.unit,
          category: merged.category,
          originRecipeIds: merged.recipeIds,
        );

        await groceryRepo.addItem(createdList.id, item);
      }

      if (mounted) {
        Navigator.pop(context);

        // Build success message
        String message = 'Created "$_listName"';
        final totalItems = ingredientsMap.length;
        final addedItems = totalItems - excludedCount;

        if (_excludePantryItems && (excludedCount > 0 || reducedCount > 0)) {
          message += '\n• Added $addedItems items';
          if (excludedCount > 0) {
            message += '\n• Excluded $excludedCount items (in pantry)';
          }
          if (reducedCount > 0) {
            message += '\n• Reduced $reducedCount quantities (partial in pantry)';
          }
        } else {
          message += ' with $addedItems items';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating list: $e')),
        );
      }
    }
  }

  void _mergeIngredient(
    Map<String, _MergedIngredient> map,
    Ingredient ingredient,
    String recipeId,
    double servingMultiplier,
  ) {
    // Normalize ingredient name (lowercase, trim)
    final normalizedName = ingredient.name.toLowerCase().trim();

    // Calculate adjusted quantity based on serving multiplier
    final adjustedQuantity = ingredient.quantity != null
        ? ingredient.quantity! * servingMultiplier
        : null;

    if (map.containsKey(normalizedName)) {
      // Merge with existing
      final existing = map[normalizedName]!;

      // Add quantity if units match
      if (existing.unit == ingredient.unit && adjustedQuantity != null) {
        existing.quantity = (existing.quantity ?? 0) + adjustedQuantity;
      }

      // Track which recipes need this ingredient
      existing.recipeIds.add(recipeId);
    } else {
      // Add new ingredient
      map[normalizedName] = _MergedIngredient(
        name: ingredient.name, // Keep original casing
        quantity: adjustedQuantity,
        unit: ingredient.unit,
        category: _categorizeIngredient(ingredient.name),
        recipeIds: [recipeId],
      );
    }
  }

  GroceryCategory _categorizeIngredient(String name) {
    final nameLower = name.toLowerCase();

    // Produce
    if (nameLower.contains('tomato') ||
        nameLower.contains('lettuce') ||
        nameLower.contains('onion') ||
        nameLower.contains('garlic') ||
        nameLower.contains('pepper') ||
        nameLower.contains('carrot') ||
        nameLower.contains('celery') ||
        nameLower.contains('potato') ||
        nameLower.contains('apple') ||
        nameLower.contains('banana') ||
        nameLower.contains('lemon') ||
        nameLower.contains('lime')) {
      return GroceryCategory.produce;
    }

    // Meat
    if (nameLower.contains('chicken') ||
        nameLower.contains('beef') ||
        nameLower.contains('pork') ||
        nameLower.contains('fish') ||
        nameLower.contains('salmon') ||
        nameLower.contains('shrimp') ||
        nameLower.contains('turkey') ||
        nameLower.contains('bacon')) {
      return GroceryCategory.meat;
    }

    // Dairy
    if (nameLower.contains('milk') ||
        nameLower.contains('cheese') ||
        nameLower.contains('butter') ||
        nameLower.contains('cream') ||
        nameLower.contains('yogurt') ||
        nameLower.contains('egg')) {
      return GroceryCategory.dairy;
    }

    // Pantry
    if (nameLower.contains('flour') ||
        nameLower.contains('sugar') ||
        nameLower.contains('rice') ||
        nameLower.contains('pasta') ||
        nameLower.contains('oil') ||
        nameLower.contains('vinegar') ||
        nameLower.contains('salt')) {
      return GroceryCategory.pantry;
    }

    // Spices
    if (nameLower.contains('pepper') ||
        nameLower.contains('oregano') ||
        nameLower.contains('basil') ||
        nameLower.contains('cumin') ||
        nameLower.contains('paprika') ||
        nameLower.contains('cinnamon')) {
      return GroceryCategory.spices;
    }

    // Condiments
    if (nameLower.contains('sauce') ||
        nameLower.contains('ketchup') ||
        nameLower.contains('mustard') ||
        nameLower.contains('mayo')) {
      return GroceryCategory.condiments;
    }

    return GroceryCategory.other;
  }

  /// Find matching pantry item using fuzzy name matching
  PantryItem? _findPantryMatch(String ingredientName, List<PantryItem> pantryItems) {
    final searchName = ingredientName.toLowerCase().trim();

    // First try exact match
    for (final item in pantryItems) {
      if (item.name.toLowerCase().trim() == searchName) {
        return item;
      }
    }

    // Then try fuzzy match - check if either contains the other
    for (final item in pantryItems) {
      final pantryName = item.name.toLowerCase().trim();

      // Check if pantry item name contains ingredient name
      // e.g., "Cherry Tomatoes" in pantry matches "tomatoes" in recipe
      if (pantryName.contains(searchName) || searchName.contains(pantryName)) {
        // Make sure it's a meaningful match (not just "a" or "the")
        if (searchName.length >= 3 || pantryName.length >= 3) {
          return item;
        }
      }
    }

    // No match found
    return null;
  }
}

/// Helper class to track merged ingredients
class _MergedIngredient {
  final String name;
  double? quantity;
  final String? unit;
  final GroceryCategory category;
  final List<String> recipeIds;

  _MergedIngredient({
    required this.name,
    this.quantity,
    this.unit,
    required this.category,
    required this.recipeIds,
  });
}
