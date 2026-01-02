require('dotenv').config();
const axios = require('axios');
const fs = require('fs');
const path = require('path');

/**
 * Test AI Recipe OCR - Extract recipes from handwritten cards
 * Uses GPT-4 Vision to read and parse handwritten recipes
 */

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

async function extractRecipeFromImage(imagePath) {
  console.log('\n╔════════════════════════════════════════════╗');
  console.log('║   AI Recipe OCR Test                      ║');
  console.log('╚════════════════════════════════════════════╝\n');

  console.log('📸 Reading handwritten recipe card...\n');
  console.log('Image:', imagePath);
  console.log('');

  try {
    // Read image file and convert to base64
    const imageBuffer = fs.readFileSync(imagePath);
    const base64Image = imageBuffer.toString('base64');
    const mimeType = imagePath.endsWith('.png') ? 'image/png' : 'image/jpeg';

    console.log('🤖 Sending to GPT-4 Vision...\n');

    const response = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      {
        model: 'gpt-4o', // GPT-4 with vision
        messages: [
          {
            role: 'system',
            content: `You are an expert at reading handwritten recipes and converting them to structured digital format.

Extract all information from the recipe card including:
- Recipe name
- All ingredients with quantities and units
- All instructions in order
- Cooking temperature and time
- Yield/servings
- Any special notes

Format the response as a natural language recipe that's easy to read and follow.`
          },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: `Please read this handwritten recipe card and convert it to a well-formatted, natural language recipe.

Include:
1. Recipe title
2. Yield/servings
3. Ingredients list (with proper measurements)
4. Step-by-step instructions
5. Baking/cooking temperature and time

Make sure to:
- Expand abbreviations (c. = cup, t. = teaspoon, etc.)
- Clarify ambiguous handwriting
- Put instructions in logical order
- Use complete sentences

Return the recipe in this JSON format:
{
  "name": "Recipe Name",
  "description": "Brief description",
  "servings": "Makes X cookies/servings",
  "prepTime": "X minutes",
  "cookTime": "X minutes",
  "ingredients": [
    {"quantity": "2.5", "unit": "cups", "name": "all-purpose flour"},
    ...
  ],
  "instructions": [
    "Step 1: ...",
    "Step 2: ...",
    ...
  ],
  "notes": "Any additional notes from the card",
  "temperature": "325°F",
  "rawText": "What the card says verbatim"
}`
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${mimeType};base64,${base64Image}`,
                  detail: 'high' // High detail for better OCR
                }
              }
            ]
          }
        ],
        max_tokens: 1500,
        temperature: 0.2, // Low temperature for accurate OCR
        response_format: { type: 'json_object' }
      },
      {
        headers: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ AI Analysis Complete!\n');

    const result = JSON.parse(response.data.choices[0].message.content);

    // Display results
    console.log('═'.repeat(50));
    console.log(`📋 Recipe: ${result.name}`);
    console.log('═'.repeat(50));
    console.log('');

    if (result.description) {
      console.log(`📝 Description: ${result.description}`);
      console.log('');
    }

    console.log(`🍪 Yield: ${result.servings}`);
    if (result.prepTime) console.log(`⏱️  Prep Time: ${result.prepTime}`);
    if (result.cookTime) console.log(`🔥 Cook Time: ${result.cookTime}`);
    if (result.temperature) console.log(`🌡️  Temperature: ${result.temperature}`);
    console.log('');

    console.log('📦 Ingredients:');
    console.log('─'.repeat(50));
    result.ingredients.forEach((ing, idx) => {
      const qty = ing.quantity || '';
      const unit = ing.unit || '';
      const name = ing.name || '';
      console.log(`  ${idx + 1}. ${qty} ${unit} ${name}`.trim());
    });
    console.log('');

    console.log('👨‍🍳 Instructions:');
    console.log('─'.repeat(50));
    result.instructions.forEach((step, idx) => {
      console.log(`  ${idx + 1}. ${step}`);
    });
    console.log('');

    if (result.notes) {
      console.log('📌 Notes:');
      console.log('─'.repeat(50));
      console.log(`  ${result.notes}`);
      console.log('');
    }

    if (result.rawText) {
      console.log('📄 Original Text (as written on card):');
      console.log('─'.repeat(50));
      console.log(result.rawText);
      console.log('');
    }

    // Token usage
    console.log('💰 API Usage:');
    console.log('─'.repeat(50));
    console.log(`  Input tokens: ${response.data.usage.prompt_tokens}`);
    console.log(`  Output tokens: ${response.data.usage.completion_tokens}`);
    console.log(`  Total tokens: ${response.data.usage.total_tokens}`);

    // Cost calculation for GPT-4o
    const inputCost = (response.data.usage.prompt_tokens / 1000000) * 5.00; // $5 per 1M input tokens
    const outputCost = (response.data.usage.completion_tokens / 1000000) * 15.00; // $15 per 1M output tokens
    const totalCost = inputCost + outputCost;
    console.log(`  Estimated cost: $${totalCost.toFixed(4)}`);
    console.log('');

    console.log('═'.repeat(50));
    console.log('');

    // Return structured recipe
    return result;

  } catch (error) {
    console.error('❌ Recipe extraction failed!\n');

    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Error:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }

    throw error;
  }
}

async function runTest() {
  console.log('\n🔍 AI Recipe OCR - Handwritten Recipe Card Reader\n');
  console.log('This test demonstrates:');
  console.log('  • Reading handwritten text with GPT-4 Vision');
  console.log('  • Converting abbreviations to full words');
  console.log('  • Structuring recipe data (ingredients, instructions)');
  console.log('  • Creating natural language recipe format\n');

  if (!OPENAI_API_KEY) {
    console.error('❌ OPENAI_API_KEY not set in .env\n');
    process.exit(1);
  }

  // Test with the recipe card image
  const imagePath = '/home/host/Documents/CPR LLC/recipe_manager/image.png';

  if (!fs.existsSync(imagePath)) {
    console.error(`❌ Image not found: ${imagePath}\n`);
    console.error('Please ensure the image is at: recipe_manager/image.png');
    process.exit(1);
  }

  try {
    const recipe = await extractRecipeFromImage(imagePath);

    console.log('✅ Recipe extraction successful!\n');
    console.log('💡 This recipe can now be:');
    console.log('   • Saved to the database');
    console.log('   • Added to meal plans');
    console.log('   • Used to generate grocery lists');
    console.log('   • Shared with other users\n');

    console.log('🚀 Next Steps:');
    console.log('   1. Integrate this into the app as "Scan Recipe Card" feature');
    console.log('   2. Allow users to take photos of recipe cards');
    console.log('   3. AI automatically extracts and saves the recipe');
    console.log('   4. User can review and edit before saving\n');

    return recipe;

  } catch (error) {
    console.error('💥 Test failed:', error.message);
    process.exit(1);
  }
}

// Run test
runTest();
