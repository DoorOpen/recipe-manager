import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/recipe.dart';

/// Cooking Mode - A distraction-free, large-text interface for following recipes while cooking
class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookingModeScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _currentStepIndex = 0;
  final Set<int> _completedSteps = {};
  final Set<int> _checkedIngredients = {};
  bool _showIngredients = false;

  @override
  void initState() {
    super.initState();
    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  List<String> get _steps {
    // Directions are already a List<String>
    return widget.recipe.directions
        .where((s) => s.trim().isNotEmpty)
        .toList();
  }

  bool get _isFirstStep => _currentStepIndex == 0;
  bool get _isLastStep => _currentStepIndex == _steps.length - 1;

  void _previousStep() {
    if (!_isFirstStep) {
      setState(() => _currentStepIndex--);
    }
  }

  void _nextStep() {
    if (_isLastStep) {
      // Mark last step as complete and exit cooking mode
      _completedSteps.add(_currentStepIndex);
      Navigator.pop(context);
    } else {
      setState(() => _currentStepIndex++);
      // Mark previous step as completed when moving forward
      _completedSteps.add(_currentStepIndex - 1);
    }
  }

  void _toggleCurrentStep() {
    setState(() {
      if (_completedSteps.contains(_currentStepIndex)) {
        _completedSteps.remove(_currentStepIndex);
      } else {
        _completedSteps.add(_currentStepIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = _steps[_currentStepIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with recipe name and exit button
            _buildHeader(theme),

            // Main content area
            Expanded(
              child: _showIngredients
                  ? _buildIngredientsView(theme)
                  : _buildStepView(theme, currentStep),
            ),

            // Navigation controls
            _buildNavigationControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Exit Cooking Mode',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.recipe.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(
              _showIngredients ? Icons.list_alt : Icons.shopping_basket,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() => _showIngredients = !_showIngredients);
            },
            tooltip: _showIngredients ? 'Show Steps' : 'Show Ingredients',
          ),
        ],
      ),
    );
  }

  Widget _buildStepView(ThemeData theme, String currentStep) {
    return GestureDetector(
      onTap: () {
        // Tap anywhere to show/hide controls (future enhancement)
      },
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Step ${_currentStepIndex + 1} of ${_steps.length}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            LinearProgressIndicator(
              value: (_currentStepIndex + 1) / _steps.length,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),

            // Current step text
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Text(
                    currentStep,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Step completion checkbox
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: _completedSteps.contains(_currentStepIndex),
                  onChanged: (value) => _toggleCurrentStep(),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return theme.colorScheme.primary;
                    }
                    return Colors.grey[700];
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  'Step Complete',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsView(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: widget.recipe.ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = widget.recipe.ingredients[index];
                final isChecked = _checkedIngredients.contains(index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Checkbox(
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
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return theme.colorScheme.primary;
                          }
                          return Colors.grey[700];
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${ingredient.quantity != null ? '${ingredient.quantity} ' : ''}${ingredient.unit ?? ''} ${ingredient.name}',
                          style: TextStyle(
                            color: isChecked ? Colors.grey[600] : Colors.white,
                            fontSize: 20,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isFirstStep ? null : _previousStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Previous'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[900],
                disabledForegroundColor: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Next/Finish button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _nextStep,
              icon: Icon(_isLastStep ? Icons.check : Icons.arrow_forward),
              label: Text(_isLastStep ? 'Finish' : 'Next'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
