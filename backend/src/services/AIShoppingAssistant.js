const axios = require('axios');

/**
 * AI Shopping Assistant
 * Uses LLM to intelligently select products based on user preferences
 *
 * Example preferences:
 * - "All organic produce, USDA Prime beef, low sodium"
 * - "Budget-friendly options, prefer store brand"
 * - "Gluten-free, dairy-free alternatives"
 */
class AIShoppingAssistant {
  constructor() {
    this.openaiApiKey = process.env.OPENAI_API_KEY;
    this.model = process.env.AI_MODEL || 'gpt-4o-mini'; // Cost-effective option
  }

  /**
   * Select best product from search results based on user preferences
   * @param {Object} item - Grocery item {name, quantity, unit, preferences}
   * @param {Array} searchResults - Array of product listings from Walmart
   * @param {string} userPreferences - Global shopping preferences
   * @returns {Object} - Selected product with reasoning
   */
  async selectBestProduct(item, searchResults, userPreferences = '') {
    try {
      // Build context for LLM
      const productsContext = searchResults.map((product, index) => ({
        index: index + 1,
        title: product.title,
        price: product.price,
        description: product.description || '',
        rating: product.rating || 'N/A',
        reviewCount: product.reviewCount || 0,
        badges: product.badges || [], // "Organic", "USDA Prime", "Low Sodium"
        brand: product.brand || '',
        size: product.size || '',
      }));

      const prompt = this.buildSelectionPrompt(item, productsContext, userPreferences);

      // Call OpenAI
      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: this.model,
          messages: [
            {
              role: 'system',
              content: 'You are an expert grocery shopping assistant. Your job is to select the best product from a list based on the user\'s shopping preferences and requirements. Consider nutrition, quality, price, and user preferences.',
            },
            {
              role: 'user',
              content: prompt,
            },
          ],
          temperature: 0.3, // Lower temperature for consistent decisions
          max_tokens: 500,
          response_format: { type: 'json_object' },
        },
        {
          headers: {
            'Authorization': `Bearer ${this.openaiApiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      const result = JSON.parse(response.data.choices[0].message.content);

      return {
        selectedIndex: result.selectedIndex - 1, // Convert to 0-indexed
        selectedProduct: searchResults[result.selectedIndex - 1],
        reasoning: result.reasoning,
        matchScore: result.matchScore,
        warnings: result.warnings || [],
      };

    } catch (error) {
      console.error('AI selection failed:', error.message);

      // Fallback: select first result
      return {
        selectedIndex: 0,
        selectedProduct: searchResults[0],
        reasoning: 'AI selection unavailable, selected first result',
        matchScore: 0,
        warnings: ['AI selection failed, using default selection'],
      };
    }
  }

  /**
   * Build prompt for product selection
   */
  buildSelectionPrompt(item, products, userPreferences) {
    return `
I need to select the best product for my grocery list.

**Item I'm looking for:**
- Name: ${item.name}
- Quantity: ${item.quantity || 1} ${item.unit || ''}
- Item-specific preferences: ${item.preferences || 'None'}

**My general shopping preferences:**
${userPreferences || 'None specified - choose best overall value'}

**Available products (from Walmart search):**
${JSON.stringify(products, null, 2)}

**Task:**
Analyze each product and select the ONE that best matches my requirements.

**Consider:**
1. Does it match my preferences? (organic, USDA grade, low sodium, etc.)
2. Quality indicators (brand, rating, badges)
3. Price vs quality balance
4. Size/quantity matches what I need
5. Any red flags (low ratings, suspicious descriptions)

**Respond in JSON format:**
{
  "selectedIndex": 1-${products.length},
  "reasoning": "Brief explanation of why this product was selected",
  "matchScore": 0-100 (how well it matches preferences),
  "warnings": ["Any concerns about this product", "..."]
}
`;
  }

  /**
   * Analyze product images to verify claims (organic label, USDA grade, etc.)
   * Uses GPT-4 Vision
   */
  async analyzeProductImage(imageUrl, lookingFor) {
    try {
      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: 'gpt-4o', // Vision model
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'text',
                  text: `Analyze this product image. I'm looking for: ${lookingFor}.

                  Check for:
                  - Organic certification labels
                  - USDA grade stamps
                  - "Low Sodium" or nutritional claims
                  - GMO-free labels
                  - Any certifications or badges

                  Respond in JSON: {"hasLabel": true/false, "details": "what you see", "confidence": 0-100}`,
                },
                {
                  type: 'image_url',
                  image_url: {
                    url: imageUrl,
                  },
                },
              ],
            },
          ],
          max_tokens: 300,
        },
        {
          headers: {
            'Authorization': `Bearer ${this.openaiApiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return JSON.parse(response.data.choices[0].message.content);

    } catch (error) {
      console.error('Image analysis failed:', error.message);
      return { hasLabel: false, details: 'Analysis unavailable', confidence: 0 };
    }
  }

  /**
   * Extract user preferences from natural language
   * "I want all organic produce and USDA Prime beef"
   * → {produce: ["organic"], beef: ["USDA Prime"]}
   */
  async parseUserPreferences(preferencesText) {
    try {
      const response = await axios.post(
        'https://api.openai.com/v1/chat/completions',
        {
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: 'Extract shopping preferences from user input into structured format.',
            },
            {
              role: 'user',
              content: `Extract shopping preferences from: "${preferencesText}"

              Return JSON:
              {
                "global": ["preferences that apply to everything"],
                "byCategory": {
                  "produce": ["organic", "non-GMO"],
                  "meat": ["USDA Prime", "grass-fed"],
                  "pantry": ["low sodium", "whole grain"]
                },
                "avoid": ["high fructose corn syrup", "artificial colors"],
                "budget": "value/standard/premium"
              }`,
            },
          ],
          temperature: 0.3,
          response_format: { type: 'json_object' },
        },
        {
          headers: {
            'Authorization': `Bearer ${this.openaiApiKey}`,
            'Content-Type': 'application/json',
          },
        }
      );

      return JSON.parse(response.data.choices[0].message.content);

    } catch (error) {
      console.error('Preference parsing failed:', error.message);
      return { global: [], byCategory: {}, avoid: [], budget: 'standard' };
    }
  }
}

module.exports = AIShoppingAssistant;
