const express = require('express');
const multer = require('multer');
const RecipeOCRService = require('../services/RecipeOCRService');

const router = express.Router();
const ocrService = new RecipeOCRService();

// Configure multer for image uploads (in-memory storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max file size
  },
  fileFilter: (req, file, cb) => {
    // Accept only images
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  }
});

/**
 * POST /api/recipes/scan
 * Extract recipe from image using AI OCR
 *
 * Request: multipart/form-data
 *   - image: Image file (JPEG, PNG, HEIC, etc.)
 *
 * Response:
 *   {
 *     success: true,
 *     recipe: { ... extracted recipe data ... },
 *     validation: { isValid: true, errors: [], warnings: [] }
 *   }
 */
router.post('/scan', upload.single('image'), async (req, res) => {
  try {
    console.log('\n📸 Recipe scan request received');

    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'No image file provided'
      });
    }

    console.log(`   File: ${req.file.originalname}`);
    console.log(`   Size: ${(req.file.size / 1024).toFixed(2)} KB`);
    console.log(`   Type: ${req.file.mimetype}`);

    // Check if OpenAI API key is configured
    if (!process.env.OPENAI_API_KEY) {
      return res.status(503).json({
        success: false,
        error: 'Recipe scanning is not configured. Please contact support.'
      });
    }

    // Extract recipe from image
    const rawRecipe = await ocrService.extractRecipe(
      req.file.buffer,
      req.file.mimetype
    );

    // Clean and normalize recipe data
    const recipe = ocrService.cleanRecipe(rawRecipe);

    // Validate recipe
    const validation = ocrService.validateRecipe(recipe);

    console.log(`✅ Recipe scanned successfully: ${recipe.name}`);

    res.json({
      success: true,
      recipe,
      validation,
      metadata: {
        tokensUsed: rawRecipe.tokensUsed,
        cost: rawRecipe.extractionCost,
        extractedAt: rawRecipe.extractedAt,
        method: rawRecipe.extractionMethod
      }
    });

  } catch (error) {
    console.error('❌ Recipe scan failed:', error.message);

    res.status(500).json({
      success: false,
      error: error.message || 'Failed to extract recipe from image'
    });
  }
});

/**
 * POST /api/recipes/scan/validate
 * Validate recipe data structure
 *
 * Request: application/json
 *   { recipe: { ... recipe data ... } }
 *
 * Response:
 *   { isValid: true, errors: [], warnings: [] }
 */
router.post('/scan/validate', express.json(), (req, res) => {
  try {
    const { recipe } = req.body;

    if (!recipe) {
      return res.status(400).json({
        isValid: false,
        errors: ['No recipe data provided']
      });
    }

    const validation = ocrService.validateRecipe(recipe);

    res.json(validation);

  } catch (error) {
    res.status(500).json({
      isValid: false,
      errors: [error.message]
    });
  }
});

/**
 * GET /api/recipes/scan/health
 * Check if OCR service is available
 */
router.get('/scan/health', (req, res) => {
  const isConfigured = !!process.env.OPENAI_API_KEY;

  res.json({
    available: isConfigured,
    service: 'gpt-4-vision',
    model: 'gpt-4o',
    status: isConfigured ? 'ready' : 'not_configured'
  });
});

module.exports = router;
