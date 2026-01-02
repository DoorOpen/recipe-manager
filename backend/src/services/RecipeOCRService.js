const axios = require('axios');

/**
 * Recipe OCR Service
 * Uses GPT-4 Vision to extract recipes from images (handwritten cards, photos, etc.)
 */
class RecipeOCRService {
  constructor() {
    this.openaiApiKey = process.env.OPENAI_API_KEY;
    this.model = 'gpt-4o'; // GPT-4 with vision capabilities
  }

  /**
   * Extract recipe from image
   * @param {Buffer|string} imageData - Image buffer or base64 string
   * @param {string} mimeType - Image MIME type (image/png, image/jpeg)
   * @returns {Object} Structured recipe data
   */
  async extractRecipe(imageData, mimeType = 'image/jpeg') {
    try {
      // Convert buffer to base64 if needed
      const base64Image = Buffer.isBuffer(imageData)
        ? imageData.toString('base64')
        : imageData;

      console.log('📸 Analyzing recipe image with GPT-4 Vision...');

      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: this.model,
          messages: [
            {
              role: 'system',
              content: `You are an expert at reading recipes from images (handwritten cards, printed recipes, photos) and converting them to structured digital format.

Extract all information accurately including:
- Recipe name
- All ingredients with quantities and units
- All instructions in order
- Cooking temperature and time
- Yield/servings
- Any special notes

Be thorough and accurate. Expand abbreviations. Format nicely.`
            },
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: `Please read this recipe image and convert it to a well-formatted, structured recipe.

Extract:
1. Recipe title
2. Description (if visible or inferred)
3. Yield/servings (e.g., "Makes 24 cookies", "Serves 4-6")
4. Prep time (if mentioned)
5. Cook time (if mentioned)
6. Total time (if mentioned)
7. Temperature (if mentioned)
8. Category (dessert, main course, etc.) - infer from ingredients
9. Cuisine (if obvious, otherwise "American")
10. Tags (e.g., ["cookies", "peanut butter", "baking"])
11. Ingredients list with proper measurements
12. Step-by-step instructions
13. Any notes or tips

Important:
- Expand ALL abbreviations (c.=cup, t.=teaspoon, tsp=teaspoon, tbsp=tablespoon, oz=ounce, lb=pound, etc.)
- Convert fractions to decimals (1/2 = 0.5, 1/4 = 0.25, etc.)
- Clarify vague handwriting based on context
- Organize instructions in logical cooking order
- If temperature is in Fahrenheit, keep it as is
- Infer cooking category from ingredients

Return ONLY valid JSON (no markdown, no code blocks) in this exact format:
{
  "name": "Recipe Name",
  "description": "Brief description of the dish",
  "servings": "Makes X servings/cookies/etc",
  "prepTime": "X minutes",
  "cookTime": "X minutes",
  "totalTime": "X minutes",
  "category": "dessert|main|side|appetizer|breakfast|drink",
  "cuisine": "American|Italian|Mexican|etc",
  "tags": ["tag1", "tag2"],
  "ingredients": [
    {
      "quantity": "2.5",
      "unit": "cups",
      "name": "all-purpose flour",
      "category": "baking"
    }
  ],
  "instructions": [
    "Preheat oven to 375°F.",
    "In a large bowl, mix margarine, peanut butter, and eggs. Beat well.",
    "Add flour, salt, and baking soda. Stir until combined."
  ],
  "notes": "Any additional notes or tips",
  "temperature": "375°F",
  "difficulty": "easy|medium|hard",
  "rawText": "What the card/image says verbatim"
}`
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: `data:${mimeType};base64,${base64Image}`,
                    detail: 'high' // High detail for better OCR accuracy
                  }
                }
              ]
            }
          ],
          max_tokens: 2000,
          temperature: 0.2, // Low temperature for accurate OCR
          response_format: { type: 'json_object' }
        },
        {
          headers: {
            'Authorization': `Bearer ${this.openaiApiKey}`,
            'Content-Type': 'application/json'
          },
          timeout: 30000 // 30 second timeout
        }
      );

      const recipe = JSON.parse(response.data.choices[0].message.content);

      // Add metadata
      recipe.extractedAt = new Date().toISOString();
      recipe.extractionMethod = 'gpt-4-vision';
      recipe.tokensUsed = response.data.usage.total_tokens;

      // Calculate cost (GPT-4o pricing)
      const inputCost = (response.data.usage.prompt_tokens / 1000000) * 5.00;
      const outputCost = (response.data.usage.completion_tokens / 1000000) * 15.00;
      recipe.extractionCost = inputCost + outputCost;

      console.log(`✅ Recipe extracted: ${recipe.name}`);
      console.log(`   Ingredients: ${recipe.ingredients.length}`);
      console.log(`   Instructions: ${recipe.instructions.length}`);
      console.log(`   Cost: $${recipe.extractionCost.toFixed(4)}`);

      return recipe;

    } catch (error) {
      console.error('❌ Recipe extraction failed:', error.message);

      if (error.response?.status === 401) {
        throw new Error('Invalid OpenAI API key');
      } else if (error.response?.status === 429) {
        throw new Error('OpenAI API rate limit exceeded. Please try again later.');
      } else if (error.response?.status === 400) {
        throw new Error('Invalid image format or size too large');
      }

      throw new Error(`Recipe extraction failed: ${error.message}`);
    }
  }

  /**
   * Validate extracted recipe data
   * @param {Object} recipe - Extracted recipe object
   * @returns {Object} Validation result
   */
  validateRecipe(recipe) {
    const errors = [];
    const warnings = [];

    // Required fields
    if (!recipe.name || recipe.name.trim().length === 0) {
      errors.push('Recipe name is required');
    }

    if (!recipe.ingredients || recipe.ingredients.length === 0) {
      errors.push('Recipe must have at least one ingredient');
    }

    if (!recipe.instructions || recipe.instructions.length === 0) {
      errors.push('Recipe must have at least one instruction');
    }

    // Warnings for missing optional fields
    if (!recipe.servings) warnings.push('Servings not specified');
    if (!recipe.prepTime && !recipe.cookTime) warnings.push('No time estimates provided');
    if (!recipe.category) warnings.push('Category not specified');

    // Validate ingredients structure
    if (recipe.ingredients) {
      recipe.ingredients.forEach((ing, idx) => {
        if (!ing.name) {
          errors.push(`Ingredient ${idx + 1} is missing name`);
        }
      });
    }

    // Validate instructions
    if (recipe.instructions) {
      recipe.instructions.forEach((inst, idx) => {
        if (!inst || inst.trim().length === 0) {
          errors.push(`Instruction ${idx + 1} is empty`);
        }
      });
    }

    return {
      isValid: errors.length === 0,
      errors,
      warnings
    };
  }

  /**
   * Clean up and normalize recipe data
   * @param {Object} recipe - Raw extracted recipe
   * @returns {Object} Cleaned recipe
   */
  cleanRecipe(recipe) {
    return {
      name: recipe.name?.trim() || 'Untitled Recipe',
      description: recipe.description?.trim() || '',
      servings: this.parseServings(recipe.servings),
      prepTime: this.parseTime(recipe.prepTime),
      cookTime: this.parseTime(recipe.cookTime),
      totalTime: this.parseTime(recipe.totalTime),
      category: recipe.category?.toLowerCase() || 'other',
      cuisine: recipe.cuisine || 'American',
      difficulty: recipe.difficulty || 'medium',
      tags: Array.isArray(recipe.tags) ? recipe.tags : [],
      ingredients: this.cleanIngredients(recipe.ingredients || []),
      instructions: this.cleanInstructions(recipe.instructions || []),
      notes: recipe.notes?.trim() || '',
      temperature: recipe.temperature || null,
      imageUrl: null, // Set by caller
      source: 'scanned',
      rawText: recipe.rawText || ''
    };
  }

  parseServings(servingsStr) {
    if (!servingsStr) return 4; // Default

    // Extract number from strings like "Makes 24 cookies", "Serves 4-6"
    const match = servingsStr.match(/(\d+)/);
    return match ? parseInt(match[1]) : 4;
  }

  parseTime(timeStr) {
    if (!timeStr) return 0;

    // Extract minutes from strings like "15 minutes", "1 hour 30 min"
    let totalMinutes = 0;

    const hourMatch = timeStr.match(/(\d+)\s*h/i);
    if (hourMatch) {
      totalMinutes += parseInt(hourMatch[1]) * 60;
    }

    const minMatch = timeStr.match(/(\d+)\s*m/i);
    if (minMatch) {
      totalMinutes += parseInt(minMatch[1]);
    }

    return totalMinutes || 0;
  }

  cleanIngredients(ingredients) {
    return ingredients.map(ing => ({
      name: ing.name?.trim() || '',
      quantity: parseFloat(ing.quantity) || null,
      unit: ing.unit?.trim() || '',
      category: this.categorizeIngredient(ing.name)
    })).filter(ing => ing.name); // Remove empty ingredients
  }

  cleanInstructions(instructions) {
    return instructions
      .map(inst => inst.trim())
      .filter(inst => inst.length > 0);
  }

  categorizeIngredient(name) {
    if (!name) return 'other';

    const lowerName = name.toLowerCase();

    // Produce
    if (/(tomato|lettuce|onion|garlic|pepper|carrot|celery|potato|vegetable|fruit)/i.test(lowerName)) {
      return 'produce';
    }

    // Meat
    if (/(beef|chicken|pork|turkey|fish|lamb|meat)/i.test(lowerName)) {
      return 'meat';
    }

    // Dairy
    if (/(milk|cheese|butter|cream|yogurt|egg)/i.test(lowerName)) {
      return 'dairy';
    }

    // Baking
    if (/(flour|sugar|baking|yeast|vanilla|chocolate|cocoa)/i.test(lowerName)) {
      return 'baking';
    }

    // Pantry
    if (/(salt|pepper|spice|oil|vinegar|sauce|paste|rice|pasta|bean)/i.test(lowerName)) {
      return 'pantry';
    }

    return 'other';
  }
}

module.exports = RecipeOCRService;
