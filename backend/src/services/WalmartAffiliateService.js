const axios = require('axios');
const AIShoppingAssistant = require('./AIShoppingAssistant');

/**
 * Walmart Affiliate API Service
 * Official API integration - NO web scraping!
 *
 * Requirements:
 * - Walmart Affiliate Program account
 * - Publisher ID
 * - API Key
 *
 * Sign up: https://affiliates.walmart.com/
 */
class WalmartAffiliateService {
  constructor(database, logger) {
    this.db = database;
    this.logger = logger;
    this.aiAssistant = new AIShoppingAssistant();

    // API Configuration
    this.baseUrl = 'https://developer.api.walmart.com/api-proxy/service/affil/product/v2';
    this.publisherId = process.env.WALMART_PUBLISHER_ID;
    this.apiKey = process.env.WALMART_API_KEY;

    // Validate credentials
    if (!this.publisherId || !this.apiKey) {
      console.warn('⚠️  Walmart API credentials not configured. Set WALMART_PUBLISHER_ID and WALMART_API_KEY in .env');
    }
  }

  /**
   * Create cart with Walmart Affiliate API
   * Much faster and more reliable than Puppeteer!
   */
  async createCart(jobId, items, userId, userPreferences = '') {
    try {
      await this.log(jobId, 'info', 'Starting AI-powered cart creation with Walmart API');
      await this.updateJobStatus(jobId, 'processing');

      const selectedProducts = [];
      const itemIds = [];

      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        await this.log(jobId, 'info', `Searching for item ${i + 1}/${items.length}: ${item.name}`);

        try {
          // Search for products
          const searchResults = await this.searchProducts(item.name);

          if (searchResults.length === 0) {
            await this.log(jobId, 'warning', `No results found for ${item.name}`);
            continue;
          }

          await this.log(jobId, 'info', `Found ${searchResults.length} options for ${item.name}`);

          // Use AI to select best product (if enabled)
          let selectedProduct;
          if (process.env.OPENAI_API_KEY && process.env.ENABLE_AI_SELECTION === 'true') {
            const aiSelection = await this.aiAssistant.selectBestProduct(
              item,
              searchResults,
              userPreferences
            );

            selectedProduct = aiSelection.selectedProduct;
            await this.log(jobId, 'info',
              `AI selected: ${selectedProduct.name} ($${selectedProduct.salePrice}) - Score: ${aiSelection.matchScore}/100`
            );
            await this.log(jobId, 'info', `Reasoning: ${aiSelection.reasoning}`);

            if (aiSelection.warnings.length > 0) {
              await this.log(jobId, 'warning', `Warnings: ${aiSelection.warnings.join(', ')}`);
            }
          } else {
            // Default: first result
            selectedProduct = searchResults[0];
            await this.log(jobId, 'info', `Selected: ${selectedProduct.name} ($${selectedProduct.salePrice})`);
          }

          // Add to cart list
          const quantity = item.quantity || 1;
          const itemIdWithQty = `${selectedProduct.itemId}:${quantity}`;
          itemIds.push(itemIdWithQty);

          selectedProducts.push({
            requested: item.name,
            selected: selectedProduct.name,
            itemId: selectedProduct.itemId,
            price: selectedProduct.salePrice,
            quantity: quantity,
            imageUrl: selectedProduct.thumbnailImage,
            reasoning: selectedProduct.reasoning || 'First result'
          });

        } catch (error) {
          await this.log(jobId, 'warning', `Failed to find ${item.name}: ${error.message}`);
        }
      }

      if (itemIds.length === 0) {
        throw new Error('Failed to find any items');
      }

      // Build cart URL with all items
      const cartUrl = this.buildCartUrl(itemIds);

      await this.log(jobId, 'info', `Successfully created cart with ${itemIds.length}/${items.length} items`);

      await this.updateJobStatus(jobId, 'completed', {
        share_url: cartUrl,
        completed_at: Date.now(),
      });

      await this.db.incrementUserJobCount(userId, true);

      return {
        success: true,
        shareUrl: cartUrl,
        itemsAdded: itemIds.length,
        selectedProducts
      };

    } catch (error) {
      await this.log(jobId, 'error', `Cart creation failed: ${error.message}`);
      await this.updateJobStatus(jobId, 'failed', {
        error_message: error.message,
        completed_at: Date.now()
      });
      await this.db.incrementUserJobCount(userId, false);
      return { success: false, error: error.message };
    }
  }

  /**
   * Search for products using Walmart API
   */
  async searchProducts(query, maxResults = 10) {
    try {
      const response = await axios.get(`${this.baseUrl}/search`, {
        params: {
          query: query,
          numItems: maxResults,
          publisherId: this.publisherId,
          apiKey: this.apiKey,
          format: 'json'
        },
        timeout: 10000
      });

      if (!response.data || !response.data.items) {
        return [];
      }

      // Transform to standard format
      return response.data.items.map(item => ({
        itemId: item.itemId,
        name: item.name,
        title: item.name,
        salePrice: item.salePrice,
        price: `$${item.salePrice}`,
        thumbnailImage: item.thumbnailImage,
        rating: item.customerRating || 'N/A',
        reviewCount: item.numReviews || 0,
        stock: item.stock || 'Unknown',
        brand: item.brandName || '',
        category: item.categoryPath || '',
        description: item.shortDescription || '',
        addToCartUrl: item.addToCartUrl || this.buildCartUrl([item.itemId]),
        badges: this.extractBadges(item)
      }));

    } catch (error) {
      console.error('Walmart API search error:', error.message);
      throw new Error(`Product search failed: ${error.message}`);
    }
  }

  /**
   * Get detailed product information
   */
  async getProductDetails(itemId) {
    try {
      const response = await axios.get(`${this.baseUrl}/items/${itemId}`, {
        params: {
          publisherId: this.publisherId,
          apiKey: this.apiKey,
          format: 'json'
        }
      });

      return response.data;
    } catch (error) {
      console.error('Product lookup error:', error.message);
      return null;
    }
  }

  /**
   * Build cart URL with multiple items
   * Format: https://walmart.com/cart/addToCart?items=12345:2,67890:1
   */
  buildCartUrl(itemIds) {
    const itemsParam = itemIds.join(',');
    return `https://walmart.com/cart/addToCart?items=${itemsParam}`;
  }

  /**
   * Extract badges from product data
   */
  extractBadges(item) {
    const badges = [];

    if (item.name && item.name.toLowerCase().includes('organic')) {
      badges.push('Organic');
    }

    if (item.bestMarketplacePrice && item.bestMarketplacePrice.clearance) {
      badges.push('Clearance');
    }

    if (item.isTwoDayShippingEligible) {
      badges.push('2-Day Shipping');
    }

    if (item.freeShippingOver35Dollars) {
      badges.push('Free Shipping');
    }

    if (item.customerRating && item.customerRating >= 4.5) {
      badges.push('Highly Rated');
    }

    return badges;
  }

  async updateJobStatus(jobId, status, additionalFields = {}) {
    const updates = {
      status,
      updated_at: Date.now(),
      ...additionalFields
    };
    await this.db.updateCartJob(jobId, updates);
  }

  async log(jobId, level, message) {
    await this.db.logJobEvent(jobId, level, message);
    console.log(`[${level.toUpperCase()}] Job ${jobId}: ${message}`);
  }
}

module.exports = WalmartAffiliateService;
