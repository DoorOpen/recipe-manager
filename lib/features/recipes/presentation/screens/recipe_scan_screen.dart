import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/recipe_scan_service.dart';
import 'scanned_recipe_review_screen.dart';

/// Screen for scanning recipes from images using AI OCR
class RecipeScanScreen extends StatefulWidget {
  const RecipeScanScreen({super.key});

  @override
  State<RecipeScanScreen> createState() => _RecipeScanScreenState();
}

class _RecipeScanScreenState extends State<RecipeScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final RecipeScanService _scanService = RecipeScanService();

  File? _selectedImage;
  bool _isScanning = false;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  Future<void> _scanRecipe() async {
    if (_selectedImage == null) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    try {
      print('📸 Starting recipe scan...');
      final result = await _scanService.scanRecipe(_selectedImage!);

      if (!mounted) return;

      if (result.success && result.recipe != null) {
        print('✅ Recipe scanned successfully: ${result.recipe!.title}');

        // Navigate to review screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScannedRecipeReviewScreen(
              scanResult: result,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to scan recipe';
        });
      }
    } catch (e) {
      print('❌ Scan error: $e');
      setState(() {
        _errorMessage = 'Error scanning recipe: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Recipe'),
        actions: [
          if (_selectedImage != null && !_isScanning)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showHelpDialog(),
              tooltip: 'Help',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_selectedImage == null) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // Error message
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Scan button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanRecipe,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.document_scanner),
                  label: Text(
                    _isScanning ? 'Scanning Recipe...' : 'Scan Recipe',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Change image button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isScanning ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.image),
                  label: const Text('Choose Different Image'),
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

        // Info text
        if (_isScanning)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Using AI to read recipe from image...\nThis may take a few seconds',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 120,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Scan a Recipe',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo of a recipe card, cookbook page, or handwritten recipe. Our AI will read it and convert it to a digital recipe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _showImageSourceDialog,
                icon: const Icon(Icons.add_a_photo),
                label: const Text(
                  'Select Image',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFeaturesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'What can be scanned:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(Icons.book, 'Cookbook pages'),
        _buildFeatureItem(Icons.credit_card, 'Recipe cards'),
        _buildFeatureItem(Icons.edit, 'Handwritten recipes'),
        _buildFeatureItem(Icons.print, 'Printed recipes'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI-powered scanning can read and understand recipe text, even handwriting!',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recipe Scanning Tips'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'For best results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTipItem('Ensure good lighting'),
              _buildTipItem('Keep the recipe flat and straight'),
              _buildTipItem('Include the entire recipe in the image'),
              _buildTipItem('Avoid shadows and glare'),
              _buildTipItem('Use high quality images'),
              const SizedBox(height: 16),
              const Text(
                'The AI will:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTipItem('Read and extract recipe text'),
              _buildTipItem('Expand abbreviations (c. → cup)'),
              _buildTipItem('Organize ingredients and steps'),
              _buildTipItem('Parse cooking times and servings'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
