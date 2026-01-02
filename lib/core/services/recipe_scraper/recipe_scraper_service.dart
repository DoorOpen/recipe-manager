import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../../models/models.dart';

/// Service for scraping recipes from websites
/// Supports JSON-LD schema.org Recipe format and HTML parsing fallback
class RecipeScraperService {
  /// Scrape a recipe from a URL
  Future<Recipe?> scrapeRecipe(String url) async {
    try {
      // Fetch the webpage
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load recipe: ${response.statusCode}');
      }

      final htmlContent = response.body;
      final document = html_parser.parse(htmlContent);

      // Try JSON-LD first (most reliable)
      final recipe = _parseJsonLd(document, url);
      if (recipe != null) {
        return recipe;
      }

      // Fallback to HTML parsing
      return _parseHtml(document, url);
    } catch (e) {
      print('Error scraping recipe: $e');
      return null;
    }
  }

  /// Parse JSON-LD structured data (schema.org Recipe)
  Recipe? _parseJsonLd(Document document, String sourceUrl) {
    try {
      // Find all JSON-LD scripts
      final scripts = document.querySelectorAll('script[type="application/ld+json"]');

      for (final script in scripts) {
        try {
          final jsonText = script.text;
          final data = jsonDecode(jsonText);

          // Handle both single object and array
          final recipes = <Map<String, dynamic>>[];
          if (data is List) {
            recipes.addAll(data.where((item) =>
              item is Map &&
              (item['@type'] == 'Recipe' ||
               (item['@type'] is List && (item['@type'] as List).contains('Recipe')))
            ).cast<Map<String, dynamic>>());
          } else if (data is Map) {
            if (data['@type'] == 'Recipe' ||
                (data['@type'] is List && (data['@type'] as List).contains('Recipe'))) {
              recipes.add(data.cast<String, dynamic>());
            } else if (data['@graph'] is List) {
              // Handle @graph format
              recipes.addAll((data['@graph'] as List)
                  .where((item) =>
                    item is Map &&
                    (item['@type'] == 'Recipe' ||
                     (item['@type'] is List && (item['@type'] as List).contains('Recipe')))
                  )
                  .cast<Map<String, dynamic>>());
            }
          }

          if (recipes.isNotEmpty) {
            return _parseRecipeFromJsonLd(recipes.first, sourceUrl);
          }
        } catch (e) {
          print('Error parsing JSON-LD script: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error in JSON-LD parsing: $e');
    }
    return null;
  }

  /// Parse recipe from JSON-LD data
  Recipe _parseRecipeFromJsonLd(Map<String, dynamic> data, String sourceUrl) {
    // Extract ingredients
    final ingredientsList = <Ingredient>[];
    final ingredientsData = data['recipeIngredient'] ?? data['ingredients'];
    if (ingredientsData is List) {
      for (final ing in ingredientsData) {
        if (ing is String) {
          ingredientsList.add(_parseIngredientString(ing));
        }
      }
    }

    // Extract directions
    final directionsList = <String>[];
    final instructionsData = data['recipeInstructions'];
    if (instructionsData is List) {
      for (final instruction in instructionsData) {
        if (instruction is String) {
          directionsList.add(instruction);
        } else if (instruction is Map) {
          final text = instruction['text'] ?? instruction['itemListElement'];
          if (text is String) {
            directionsList.add(text);
          } else if (text is List) {
            for (final step in text) {
              if (step is Map && step['text'] is String) {
                directionsList.add(step['text']);
              }
            }
          }
        }
      }
    } else if (instructionsData is String) {
      // Split by newlines or periods
      directionsList.addAll(
        instructionsData.split(RegExp(r'\n|\.(?=\s|$)'))
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
      );
    }

    // Extract images
    final photoUrls = <String>[];
    final imageData = data['image'];
    if (imageData is String) {
      photoUrls.add(_normalizeUrl(imageData, sourceUrl));
    } else if (imageData is List) {
      for (final img in imageData) {
        if (img is String) {
          photoUrls.add(_normalizeUrl(img, sourceUrl));
        } else if (img is Map && img['url'] is String) {
          photoUrls.add(_normalizeUrl(img['url'], sourceUrl));
        }
      }
    } else if (imageData is Map && imageData['url'] is String) {
      photoUrls.add(_normalizeUrl(imageData['url'], sourceUrl));
    }

    // Extract nutrition
    Nutrition? nutrition;
    final nutritionData = data['nutrition'];
    if (nutritionData is Map) {
      nutrition = Nutrition(
        calories: _parseNumber(nutritionData['calories'])?.toInt(),
        protein: _parseNumber(nutritionData['proteinContent']),
        carbs: _parseNumber(nutritionData['carbohydrateContent']),
        fat: _parseNumber(nutritionData['fatContent']),
        fiber: _parseNumber(nutritionData['fiberContent']),
        sodium: _parseNumber(nutritionData['sodiumContent'])?.toInt(),
      );
    }

    // Parse times (ISO 8601 duration format: PT30M)
    final prepTime = _parseDuration(data['prepTime']);
    final cookTime = _parseDuration(data['cookTime']);

    // Parse yield/servings
    int servings = 4; // default
    final yieldData = data['recipeYield'] ?? data['yield'];
    if (yieldData != null) {
      servings = _parseServings(yieldData);
    }

    // Extract categories
    final categories = <String>[];
    final categoryData = data['recipeCategory'];
    if (categoryData is String) {
      categories.add(categoryData);
    } else if (categoryData is List) {
      categories.addAll(categoryData.whereType<String>());
    }

    final cuisineData = data['recipeCuisine'];
    if (cuisineData is String) {
      categories.add(cuisineData);
    } else if (cuisineData is List) {
      categories.addAll(cuisineData.whereType<String>());
    }

    final now = DateTime.now();
    return Recipe(
      id: now.millisecondsSinceEpoch.toString(),
      title: data['name'] ?? 'Untitled Recipe',
      description: data['description'],
      ingredients: ingredientsList,
      directions: directionsList,
      categories: categories,
      prepTimeMinutes: prepTime,
      cookTimeMinutes: cookTime,
      servings: servings,
      difficulty: null,
      rating: _parseRating(data['aggregateRating']),
      photoUrls: photoUrls,
      sourceUrl: sourceUrl,
      notes: null,
      nutrition: nutrition,
      createdAt: now,
      updatedAt: now,
      isFavorite: false,
      hasCooked: false,
    );
  }

  /// Parse HTML as fallback (less reliable)
  Recipe? _parseHtml(Document document, String sourceUrl) {
    try {
      // Try common selectors for recipe sites
      final title = _extractText(document, [
        'h1.recipe-title',
        'h1[itemprop="name"]',
        '.recipe-header h1',
        'h1',
      ]) ?? 'Untitled Recipe';

      final description = _extractText(document, [
        '.recipe-description',
        '[itemprop="description"]',
        'meta[name="description"]',
      ]);

      // Extract ingredients
      final ingredientsList = <Ingredient>[];
      final ingredientElements = document.querySelectorAll([
        '.ingredient',
        '[itemprop="recipeIngredient"]',
        '.ingredients li',
        '.recipe-ingredients li',
      ].join(','));

      for (final element in ingredientElements) {
        final text = element.text.trim();
        if (text.isNotEmpty) {
          ingredientsList.add(_parseIngredientString(text));
        }
      }

      // Extract directions
      final directionsList = <String>[];
      final directionElements = document.querySelectorAll([
        '.instruction',
        '[itemprop="recipeInstructions"]',
        '.instructions li',
        '.recipe-directions li',
        '.recipe-steps li',
      ].join(','));

      for (final element in directionElements) {
        final text = element.text.trim();
        if (text.isNotEmpty) {
          directionsList.add(text);
        }
      }

      // If no ingredients or directions found, return null
      if (ingredientsList.isEmpty || directionsList.isEmpty) {
        return null;
      }

      final now = DateTime.now();
      return Recipe(
        id: now.millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        ingredients: ingredientsList,
        directions: directionsList,
        categories: [],
        prepTimeMinutes: null,
        cookTimeMinutes: null,
        servings: 4,
        difficulty: null,
        rating: null,
        photoUrls: [],
        sourceUrl: sourceUrl,
        notes: null,
        nutrition: null,
        createdAt: now,
        updatedAt: now,
        isFavorite: false,
        hasCooked: false,
      );
    } catch (e) {
      print('Error in HTML parsing: $e');
      return null;
    }
  }

  // ============================================================================
  // Helper methods
  // ============================================================================

  /// Extract text from document using selectors
  String? _extractText(Document document, List<String> selectors) {
    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = element.text.trim();
        if (text.isNotEmpty) {
          return text;
        }
        // Check for meta tags
        if (selector.startsWith('meta')) {
          final content = element.attributes['content'];
          if (content != null && content.isNotEmpty) {
            return content;
          }
        }
      }
    }
    return null;
  }

  /// Parse an ingredient string into an Ingredient object
  Ingredient _parseIngredientString(String text) {
    // Simple parsing - could be improved with more sophisticated regex
    final cleaned = text.trim();

    // Try to extract quantity and unit
    final quantityPattern = RegExp(r'^(\d+(?:[\./]\d+)?(?:\s*-\s*\d+(?:[\./]\d+)?)?)\s*');
    final match = quantityPattern.firstMatch(cleaned);

    if (match != null) {
      final quantityStr = match.group(1)!;
      final quantity = _parseQuantity(quantityStr);
      final rest = cleaned.substring(match.end).trim();

      // Try to extract unit
      final unitPattern = RegExp(r'^([a-zA-Z]+\.?)\s+');
      final unitMatch = unitPattern.firstMatch(rest);

      if (unitMatch != null) {
        final unit = unitMatch.group(1);
        final name = rest.substring(unitMatch.end).trim();
        return Ingredient(name: name, quantity: quantity, unit: unit);
      }

      return Ingredient(name: rest, quantity: quantity);
    }

    return Ingredient(name: cleaned);
  }

  /// Parse a quantity string (handles fractions like "1/2" or ranges like "1-2")
  double? _parseQuantity(String text) {
    text = text.trim();

    // Handle fractions
    if (text.contains('/')) {
      final parts = text.split('/');
      if (parts.length == 2) {
        final num = double.tryParse(parts[0]);
        final denom = double.tryParse(parts[1]);
        if (num != null && denom != null && denom != 0) {
          return num / denom;
        }
      }
    }

    // Handle ranges (take the first number)
    if (text.contains('-')) {
      final parts = text.split('-');
      return double.tryParse(parts[0].trim());
    }

    return double.tryParse(text);
  }

  /// Parse ISO 8601 duration (e.g., "PT30M" = 30 minutes)
  int? _parseDuration(dynamic duration) {
    if (duration == null) return null;

    final durationStr = duration.toString();
    if (!durationStr.startsWith('PT')) return null;

    final hoursMatch = RegExp(r'(\d+)H').firstMatch(durationStr);
    final minutesMatch = RegExp(r'(\d+)M').firstMatch(durationStr);

    int minutes = 0;
    if (hoursMatch != null) {
      minutes += int.parse(hoursMatch.group(1)!) * 60;
    }
    if (minutesMatch != null) {
      minutes += int.parse(minutesMatch.group(1)!);
    }

    return minutes > 0 ? minutes : null;
  }

  /// Parse servings from various formats
  int _parseServings(dynamic yieldData) {
    if (yieldData is int) return yieldData;
    if (yieldData is String) {
      // Extract first number from string
      final match = RegExp(r'\d+').firstMatch(yieldData);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 4;
      }
    }
    return 4;
  }

  /// Parse rating from aggregateRating
  double? _parseRating(dynamic rating) {
    if (rating == null) return null;
    if (rating is Map) {
      final value = rating['ratingValue'];
      return _parseNumber(value);
    }
    return null;
  }

  /// Parse a number from various formats
  double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      // Remove units and parse
      final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// Normalize URL (handle relative URLs)
  String _normalizeUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    try {
      final base = Uri.parse(baseUrl);
      if (url.startsWith('//')) {
        return '${base.scheme}:$url';
      }
      if (url.startsWith('/')) {
        return '${base.scheme}://${base.host}$url';
      }
      return '${base.scheme}://${base.host}/${base.pathSegments.take(base.pathSegments.length - 1).join('/')}/$url';
    } catch (e) {
      return url;
    }
  }
}
