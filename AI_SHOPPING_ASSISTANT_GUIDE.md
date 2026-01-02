# AI Shopping Assistant - Implementation Guide

## Overview

Transform your cart automation from "add first search result" to **intelligent product selection** based on user preferences!

**Example**:
```
User preference: "I want all organic produce and USDA Prime beef"

Without AI:
- Searches "tomatoes" → Adds first result (regular tomatoes $2.99)

With AI:
- Searches "tomatoes" → Gets 10 results
- AI analyzes: "Great Value Tomatoes $2.99", "Organic Roma Tomatoes $4.99", etc.
- AI selects: "Organic Roma Tomatoes" (matches "organic produce" preference)
- Adds to cart with reasoning: "Selected organic option per your preferences"
```

---

## What We Built

### 1. AIShoppingAssistant Service
- Uses OpenAI GPT-4o-mini ($0.15 per 1M tokens)
- Analyzes 5-10 products per item
- Selects best match based on preferences
- Returns match score + reasoning
- **Cost**: ~$0.01 per grocery list (20 items)

### 2. SmartWalmartCartService
- Extracts product data (title, price, rating, badges)
- Sends to AI for analysis
- Adds AI-selected product to cart
- Logs reasoning for transparency

### 3. User Preference System
- Global preferences: "organic, low sodium, budget-friendly"
- Category-specific: "USDA Prime beef", "wild-caught fish"
- Avoid lists: "high fructose corn syrup", "artificial colors"

---

## Existing Frameworks & Tools

### 1. **Langchain** (Recommended)
**Best for**: LLM orchestration and structured output

```bash
npm install langchain @langchain/openai
```

**Why it's great**:
- ✅ Built-in prompt templates
- ✅ Structured output parsing
- ✅ Easy model switching (OpenAI → Anthropic → Local)
- ✅ Built-in retry logic
- ✅ Cost tracking

**Example**:
```javascript
import { ChatOpenAI } from "@langchain/openai";
import { StructuredOutputParser } from "langchain/output_parsers";

const model = new ChatOpenAI({
  modelName: "gpt-4o-mini",
  temperature: 0.3
});

const parser = StructuredOutputParser.fromNamesAndDescriptions({
  selectedIndex: "The index of the selected product (1-10)",
  reasoning: "Why this product was selected",
  matchScore: "How well it matches preferences (0-100)"
});

const chain = model.pipe(parser);
const result = await chain.invoke(prompt);
```

### 2. **AutoGPT / BabyAGI**
**Best for**: Autonomous shopping agents

**GitHub**: https://github.com/Significant-Gravitas/AutoGPT

**Concept**: AI agent that can:
- Browse websites autonomously
- Make decisions
- Complete multi-step tasks

**Challenges**:
- Too complex for simple product selection
- Expensive (lots of API calls)
- Less predictable

### 3. **Browser-Use** (New!)
**Best for**: LLM-controlled browser automation

**GitHub**: https://github.com/browser-use/browser-use

```python
from browser_use import Agent
from langchain_openai import ChatOpenAI

agent = Agent(
    task="Find and add organic tomatoes to Walmart cart",
    llm=ChatOpenAI(model="gpt-4o")
)

result = agent.run()
```

**Why it's interesting**:
- ✅ LLM controls Playwright browser
- ✅ Can navigate complex UIs
- ✅ Self-healing (adapts to UI changes)
- ❌ Python only (but could call from Node.js)
- ❌ Expensive ($0.50-$2 per cart)

### 4. **Playwright with AI**
**Best for**: Reliable browser automation + AI decisions

```javascript
const { chromium } = require('playwright');
const OpenAI = require('openai');

const browser = await chromium.launch();
const page = await browser.newPage();

// Get screenshot of product listings
await page.goto('walmart.com/search?q=tomatoes');
const screenshot = await page.screenshot();

// Send to GPT-4 Vision
const response = await openai.chat.completions.create({
  model: "gpt-4o",
  messages: [{
    role: "user",
    content: [
      { type: "text", text: "Which product is organic?" },
      { type: "image_url", image_url: { url: screenshot }}
    ]
  }]
});
```

### 5. **Octoparse** (Commercial)
**Best for**: Visual web scraping + AI

**What it does**:
- Visual scraper (no coding)
- AI-powered data extraction
- Cloud-based
- **Cost**: $75/month

**Not recommended**: Too expensive, less control

### 6. **Apify + OpenAI**
**Best for**: Managed scraping + AI analysis

**GitHub**: https://github.com/apify/apify-sdk-js

```javascript
const Apify = require('apify');

// Scrape Walmart search results
const results = await Apify.call('apify/walmart-scraper', {
  search: 'organic tomatoes',
  maxResults: 10
});

// Analyze with AI
const selected = await selectBestProduct(results);
```

**Pros**:
- Managed scrapers (handles blocking, proxies)
- Pre-built Walmart scraper

**Cons**:
- Additional cost ($49/month)

---

## Migration Path: OpenAI → Open Source

### Phase 1: Start with OpenAI (Recommended)

**Why**:
- Fast to implement ✅
- Reliable results ✅
- Low cost ($0.01 per cart) ✅
- Easy to test and iterate ✅

**Cost Analysis**:
- 1,000 carts/month × $0.01 = $10/month
- **Very affordable for MVP**

### Phase 2: Add Llama 3.2 for Cost Savings

**Option A: Self-Hosted Llama**

```bash
# Install Ollama (local LLM runtime)
curl https://ollama.ai/install.sh | sh

# Download Llama 3.2 (3B model, fast)
ollama pull llama3.2:3b

# Download Llama 3.2 Vision (for image analysis)
ollama pull llama3.2-vision:11b
```

**Use in code**:
```javascript
const axios = require('axios');

async function selectWithLlama(products, preferences) {
  const response = await axios.post('http://localhost:11434/api/chat', {
    model: 'llama3.2:3b',
    messages: [{
      role: 'user',
      content: buildSelectionPrompt(products, preferences)
    }],
    format: 'json'
  });

  return JSON.parse(response.data.message.content);
}
```

**Pros**:
- ✅ FREE (after hardware cost)
- ✅ No API limits
- ✅ Private (data stays local)
- ✅ Fast inference (~200ms)

**Cons**:
- ❌ Need GPU server (~$50/month DigitalOcean GPU droplet)
- ❌ Slightly lower quality than GPT-4
- ❌ More maintenance

**Cost Comparison**:
- OpenAI: $10/month (1,000 carts)
- Self-hosted Llama: $50/month server + $0/cart = $50/month
- **Break-even**: 5,000 carts/month

**Recommendation**: Use OpenAI until you hit 5,000+ carts/month

### Phase 3: Hybrid Approach (Best of Both)

```javascript
class HybridAIAssistant {
  async selectBestProduct(products, preferences) {
    // Use fast local model for simple decisions
    if (products.length <= 3 || !preferences) {
      return await this.selectWithLlama(products, preferences);
    }

    // Use GPT-4 for complex preference matching
    if (preferences.includes('organic') || preferences.includes('USDA')) {
      return await this.selectWithOpenAI(products, preferences);
    }

    // Default: local model
    return await this.selectWithLlama(products, preferences);
  }
}
```

**Cost savings**: 60-70% reduction

---

## Recommended Open-Source Models

### 1. **Llama 3.2 3B** (Best Overall)
- **Speed**: Very fast (200ms)
- **Quality**: Good for product selection
- **Size**: 3GB (fits on CPU)
- **Cost**: FREE
- **Use for**: General product selection

### 2. **Llama 3.2 Vision 11B** (For Image Analysis)
- **Speed**: Moderate (1-2s)
- **Quality**: Excellent for reading labels
- **Size**: 11GB (needs GPU)
- **Use for**: Verifying organic labels, USDA stamps

### 3. **Mixtral 8x7B** (Most Accurate)
- **Speed**: Slower (2-3s)
- **Quality**: Near GPT-4 level
- **Size**: 47GB (needs good GPU)
- **Use for**: Complex preference matching

### 4. **Phi-3 Mini** (Fastest)
- **Speed**: Blazing fast (50ms)
- **Quality**: Good for simple tasks
- **Size**: 2GB (runs on phone!)
- **Use for**: Quick filtering

---

## GitHub Projects to Explore

### 1. **Langchain**
https://github.com/langchain-ai/langchainjs
- ⭐ 51k stars
- Best for: LLM orchestration
- **Use it**: Switching between OpenAI and local models

### 2. **Ollama**
https://github.com/ollama/ollama
- ⭐ 45k stars
- Best for: Running local LLMs
- **Use it**: Self-hosted Llama

### 3. **Browser-Use**
https://github.com/browser-use/browser-use
- ⭐ 3k stars (new!)
- Best for: LLM-controlled browsing
- **Use it**: Inspiration for UI understanding

### 4. **GPT4All**
https://github.com/nomic-ai/gpt4all
- ⭐ 68k stars
- Best for: Local LLM runtime (like Ollama)
- **Use it**: Alternative to Ollama

### 5. **LaVague** (AI Web Agent)
https://github.com/lavague-ai/LaVague
- ⭐ 4k stars
- Best for: AI that can use any website
- **Use it**: Autonomous shopping agent

### 6. **E2B** (AI Code Execution)
https://github.com/e2b-dev/e2b
- ⭐ 6k stars
- Best for: Running AI-generated code safely
- **Use it**: Dynamic scraper generation

---

## Recommended Implementation Path

### Week 1: OpenAI MVP
```javascript
// backend/src/services/AIShoppingAssistant.js
// ✅ Already built!
// Just add OPENAI_API_KEY to .env
```

**Cost**: $10-20/month
**Time**: Already done! ✅

### Week 2: Test & Refine
- Test with real users
- Collect feedback on AI selections
- Tune prompts for better matching
- Add more preference types

### Week 3: Add Llama (if needed)
```bash
# Only if you hit 5,000+ carts/month

# Deploy GPU server
# Install Ollama
# Update AIShoppingAssistant to support both
```

**Cost**: $50/month (GPU server)
**Savings**: Free inference after setup

### Month 2-3: Hybrid System
- Use Llama for simple selections (70% of cases)
- Use OpenAI for complex preferences (30% of cases)
- **Total cost**: $5-10/month

---

## Flutter Integration

Update the grocery list model to include preferences:

```dart
// lib/core/models/grocery_item.dart

class GroceryItem {
  final String id;
  final String name;
  final double? quantity;
  final String? unit;
  final String? preferences; // NEW: "organic", "USDA Prime", etc.
  // ...

  GroceryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.preferences, // NEW
    // ...
  });
}
```

Add global shopping preferences:

```dart
// lib/features/settings/shopping_preferences_screen.dart

class ShoppingPreferencesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shopping Preferences')),
      body: ListView(
        children: [
          // Global preferences
          ListTile(
            title: Text('General Preferences'),
            subtitle: Text('Apply to all items'),
          ),
          CheckboxListTile(
            title: Text('Prefer Organic'),
            value: prefs.preferOrganic,
            onChanged: (value) => setState(() => prefs.preferOrganic = value),
          ),
          CheckboxListTile(
            title: Text('Budget-Friendly'),
            value: prefs.budgetFriendly,
            onChanged: (value) => setState(() => prefs.budgetFriendly = value),
          ),

          Divider(),

          // Category-specific
          ListTile(
            title: Text('Produce'),
            trailing: DropdownButton(
              value: prefs.produceQuality,
              items: ['Any', 'Organic', 'Local'].map((e) =>
                DropdownMenuItem(value: e, child: Text(e))
              ).toList(),
              onChanged: (value) => setState(() => prefs.produceQuality = value),
            ),
          ),
          ListTile(
            title: Text('Meat'),
            trailing: DropdownButton(
              value: prefs.meatQuality,
              items: ['Any', 'USDA Prime', 'Grass-Fed', 'Organic'].map((e) =>
                DropdownMenuItem(value: e, child: Text(e))
              ).toList(),
              onChanged: (value) => setState(() => prefs.meatQuality = value),
            ),
          ),

          Divider(),

          // Avoid list
          ListTile(
            title: Text('Avoid Ingredients'),
          ),
          Wrap(
            children: [
              Chip(label: Text('High Fructose Corn Syrup'), onDeleted: () {}),
              Chip(label: Text('Artificial Colors'), onDeleted: () {}),
              ActionChip(
                label: Text('+ Add'),
                onPressed: () => _showAddAvoidIngredient(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

Send preferences to backend:

```dart
// Update PremiumCartService
Future<CartJob> createWalmartCart(
  List<GroceryItem> items, {
  String? userPreferences, // NEW
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/api/cart/create-walmart'),
    headers: {
      'Authorization': 'Bearer ${getAuthToken()}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'items': items.map((item) => {
        'name': item.name,
        'quantity': item.quantity ?? 1,
        'preferences': item.preferences, // NEW
      }).toList(),
      'userPreferences': userPreferences, // NEW: "organic produce, USDA Prime beef"
    }),
  );
  // ...
}
```

---

## Cost Comparison

### OpenAI GPT-4o-mini
| Usage | Cost/Month |
|-------|------------|
| 100 carts | $1 |
| 1,000 carts | $10 |
| 10,000 carts | $100 |
| 100,000 carts | $1,000 |

### Self-Hosted Llama 3.2
| Setup | Cost |
|-------|------|
| GPU Server (DigitalOcean) | $50/month |
| Inference | $0 |
| **Break-even** | **5,000 carts/month** |

### Hybrid Approach
| Usage | Cost/Month |
|-------|------------|
| 10,000 carts (70% Llama, 30% OpenAI) | $50 + $30 = $80 |
| **Savings vs OpenAI only** | **$20/month** |

---

## Example Prompts

### Product Selection
```
I need organic tomatoes. Here are 5 options:

1. Great Value Tomatoes - $2.99 - Regular
2. Organic Roma Tomatoes - $4.99 - USDA Organic
3. Heirloom Tomatoes - $6.99 - Local, Organic
4. Cherry Tomatoes - $3.49 - Regular
5. Organic Beefsteak Tomatoes - $5.49 - USDA Organic

My preference: "organic produce, budget-friendly when possible"

Select best option and explain why.
```

**AI Response**:
```json
{
  "selectedIndex": 2,
  "reasoning": "Organic Roma Tomatoes ($4.99) meet your organic requirement and are the most budget-friendly organic option. Heirloom tomatoes are pricier, and non-organic options don't match your preference.",
  "matchScore": 95,
  "warnings": []
}
```

---

## Next Steps

1. **Add OpenAI API key** to .env:
   ```
   OPENAI_API_KEY=sk-...
   AI_MODEL=gpt-4o-mini
   ```

2. **Update cart route** to use SmartWalmartCartService

3. **Test with real preferences**:
   ```bash
   curl -X POST http://localhost:3000/api/cart/create-walmart \
     -H "Authorization: Bearer test-user-123" \
     -H "Content-Type: application/json" \
     -d '{
       "items": [{"name": "Tomatoes", "quantity": 2}],
       "userPreferences": "I want all organic produce"
     }'
   ```

4. **Monitor costs** in OpenAI dashboard

5. **Switch to Llama** when you hit 5,000 carts/month

---

## Summary

You now have:
- ✅ AI-powered product selection
- ✅ User preference system
- ✅ Cost-effective OpenAI integration
- ✅ Migration path to open-source
- ✅ Hybrid approach for scale

**Estimated costs**:
- MVP (OpenAI): $10-20/month
- Scale (Hybrid): $50-80/month
- **Per cart**: $0.01 (vs $0.00 for competitors)

**Value add**: Users get exactly what they want, every time! 🎯

This is a **killer feature** that justifies premium pricing! 💰
