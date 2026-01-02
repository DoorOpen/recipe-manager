import 'package:flutter/material.dart';
import '../../../../core/models/models.dart' as models;
import '../../../../shared/theme/app_theme.dart';

/// A premium glass morphism card displaying recipe's summary
class RecipeCard extends StatelessWidget {
  final models.Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showOptionsMenu(context),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _buildRecipeImage(context),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Favorite Button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            recipe.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: recipe.isFavorite
                                ? Colors.red.shade400
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          onPressed: onFavoriteToggle,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Metadata Row
                    _buildMetadataRow(theme),

                    // Rating
                    if (recipe.rating != null) ...[
                      const SizedBox(height: 8),
                      _buildRatingRow(theme),
                    ],

                    const SizedBox(height: 12),

                    // Category Chips & Badges
                    Row(
                      children: [
                        Expanded(
                          child: recipe.categories.isNotEmpty
                              ? _buildCategoryChips(theme)
                              : const SizedBox(),
                        ),
                        if (recipe.hasCooked) _buildCookedBadge(colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build recipe image
  Widget _buildRecipeImage(BuildContext context) {
    final hasPhoto = recipe.photoUrls.isNotEmpty;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: hasPhoto
          ? Image.network(
              recipe.photoUrls.first,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            )
          : _buildPlaceholderImage(),
    );
  }

  /// Build placeholder with minimal design
  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 72,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }

  /// Build metadata row with minimal icons
  Widget _buildMetadataRow(ThemeData theme) {
    final metadata = <Widget>[];

    // Total Time
    if (recipe.totalTimeMinutes != null) {
      metadata.add(
        _buildMetadataItem(
          icon: Icons.schedule_rounded,
          label: '${recipe.totalTimeMinutes} min',
          theme: theme,
        ),
      );
    }

    // Servings
    metadata.add(
      _buildMetadataItem(
        icon: Icons.people_rounded,
        label: '${recipe.servings}',
        theme: theme,
      ),
    );

    // Difficulty
    if (recipe.difficulty != null) {
      metadata.add(
        _buildMetadataItem(
          icon: Icons.bar_chart_rounded,
          label: recipe.difficulty!,
          theme: theme,
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: metadata,
    );
  }

  /// Build a single metadata item with minimal design
  Widget _buildMetadataItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build rating row with minimal design
  Widget _buildRatingRow(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final rating = recipe.rating ?? 0;
          return Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: Colors.amber.shade700,
          );
        }),
        const SizedBox(width: 6),
        Text(
          '${recipe.rating?.toStringAsFixed(1)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build category chips with minimal design
  Widget _buildCategoryChips(ThemeData theme) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: recipe.categories.take(3).map((category) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            category,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Build "Cooked" badge with minimal design
  Widget _buildCookedBadge(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Cooked',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.successColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Show options menu
  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Recipe'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
              ),
              title: Text(
                recipe.isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
              ),
              onTap: () {
                Navigator.pop(context);
                onFavoriteToggle?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Recipe'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Recipe',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show delete confirmation
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
