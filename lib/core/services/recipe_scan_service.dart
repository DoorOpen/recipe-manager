import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

import '../models/recipe.dart';

/// Service for scanning recipes from images using AI OCR
class RecipeScanService {
  final String baseUrl;

  RecipeScanService({this.baseUrl = 'http://localhost:3000'});

  /// Scan a recipe from an image file
  /// Returns the extracted recipe data
  Future<ScanRecipeResult> scanRecipe(File imageFile) async {
    try {
      print('📸 Scanning recipe from image: ${imageFile.path}');

      // Create multipart request
      final uri = Uri.parse('$baseUrl/api/recipes/scan');
      final request = http.MultipartRequest('POST', uri);

      // Add image file
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', _getImageType(imageFile.path)),
      );

      request.files.add(multipartFile);

      print('   Sending to AI OCR service...');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('   Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final recipeData = data['recipe'];
          final validation = data['validation'];
          final metadata = data['metadata'];

          print('✅ Recipe scanned successfully: ${recipeData['name']}');
          print('   Ingredients: ${recipeData['ingredients'].length}');
          print('   Instructions: ${recipeData['instructions'].length}');
          print('   Cost: \$${metadata['cost'].toStringAsFixed(4)}');

          // Convert to Recipe object
          final recipe = _convertToRecipe(recipeData);

          return ScanRecipeResult(
            success: true,
            recipe: recipe,
            rawData: recipeData,
            validation: RecipeValidation.fromJson(validation),
            metadata: ScanMetadata.fromJson(metadata),
          );
        } else {
          throw Exception(data['error'] ?? 'Unknown error');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to scan recipe');
      }
    } catch (e) {
      print('❌ Recipe scan failed: $e');
      return ScanRecipeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Check if OCR service is available
  Future<bool> isAvailable() async {
    try {
      final uri = Uri.parse('$baseUrl/api/recipes/scan/health');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['available'] == true;
      }

      return false;
    } catch (e) {
      print('Failed to check OCR service: $e');
      return false;
    }
  }

  /// Validate recipe data
  Future<RecipeValidation> validateRecipe(Map<String, dynamic> recipeData) async {
    try {
      final uri = Uri.parse('$baseUrl/api/recipes/scan/validate');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'recipe': recipeData}),
      );

      if (response.statusCode == 200) {
        return RecipeValidation.fromJson(json.decode(response.body));
      }

      throw Exception('Validation failed');
    } catch (e) {
      return RecipeValidation(
        isValid: false,
        errors: [e.toString()],
      );
    }
  }

  String _getImageType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'heic':
        return 'heic';
      default:
        return 'jpeg';
    }
  }

  Recipe _convertToRecipe(Map<String, dynamic> data) {
    // Convert ingredients
    final ingredients = (data['ingredients'] as List).map((ing) {
      return Ingredient(
        name: ing['name'],
        quantity: ing['quantity']?.toDouble(),
        unit: ing['unit'] ?? '',
      );
    }).toList();

    // Convert instructions to list of strings
    final directions = (data['instructions'] as List)
        .map((inst) => inst.toString())
        .toList();

    // Build categories list from category, cuisine, and tags
    final categories = <String>[];
    if (data['category'] != null) categories.add(data['category']);
    if (data['cuisine'] != null) categories.add(data['cuisine']);
    if (data['tags'] != null) {
      categories.addAll((data['tags'] as List).map((t) => t.toString()));
    }

    return Recipe(
      id: '', // Will be set when saved
      title: data['name'] ?? 'Untitled Recipe',
      description: data['description'],
      ingredients: ingredients,
      directions: directions,
      servings: data['servings'] != null ? _parseServings(data['servings']) : 4,
      prepTimeMinutes: data['prepTime'] ?? 0,
      cookTimeMinutes: data['cookTime'] ?? 0,
      difficulty: data['difficulty'] ?? 'medium',
      categories: categories,
      photoUrls: const [], // Will be set later
      notes: data['notes'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isFavorite: false,
      hasCooked: false,
    );
  }

  int _parseServings(dynamic servings) {
    if (servings is int) return servings;
    if (servings is String) {
      final match = RegExp(r'\d+').firstMatch(servings);
      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 4;
      }
    }
    return 4;
  }
}

/// Result of recipe scanning
class ScanRecipeResult {
  final bool success;
  final Recipe? recipe;
  final Map<String, dynamic>? rawData;
  final RecipeValidation? validation;
  final ScanMetadata? metadata;
  final String? error;

  ScanRecipeResult({
    required this.success,
    this.recipe,
    this.rawData,
    this.validation,
    this.metadata,
    this.error,
  });
}

/// Recipe validation result
class RecipeValidation {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  RecipeValidation({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  factory RecipeValidation.fromJson(Map<String, dynamic> json) {
    return RecipeValidation(
      isValid: json['isValid'] ?? false,
      errors: (json['errors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      warnings: (json['warnings'] as List?)?.map((w) => w.toString()).toList() ?? [],
    );
  }
}

/// Metadata about the scan
class ScanMetadata {
  final int tokensUsed;
  final double cost;
  final DateTime extractedAt;
  final String method;

  ScanMetadata({
    required this.tokensUsed,
    required this.cost,
    required this.extractedAt,
    required this.method,
  });

  factory ScanMetadata.fromJson(Map<String, dynamic> json) {
    return ScanMetadata(
      tokensUsed: json['tokensUsed'] ?? 0,
      cost: (json['cost'] ?? 0.0).toDouble(),
      extractedAt: DateTime.parse(json['extractedAt']),
      method: json['method'] ?? 'gpt-4-vision',
    );
  }
}
