const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
const AIShoppingAssistant = require('./AIShoppingAssistant');

puppeteer.use(StealthPlugin());

/**
 * Smart Walmart Cart Service with AI Product Selection
 * Combines web scraping with LLM-powered product filtering
 */
class SmartWalmartCartService {
  constructor(database, logger) {
    this.db = database;
    this.logger = logger;
    this.aiAssistant = new AIShoppingAssistant();
    this.proxyConfig = this.getProxyConfig();
  }

  getProxyConfig() {
    if (process.env.PROXY_HOST && process.env.PROXY_PORT) {
      return {
        host: process.env.PROXY_HOST,
        port: process.env.PROXY_PORT,
        username: process.env.PROXY_USERNAME,
        password: process.env.PROXY_PASSWORD
      };
    }
    return null;
  }

  async createCart(jobId, items, userId, userPreferences = '') {
    let browser;

    try {
      await this.log(jobId, 'info', 'Starting AI-powered cart creation');
      await this.updateJobStatus(jobId, 'processing');

      // Parse user preferences if provided
      let parsedPreferences = null;
      if (userPreferences) {
        await this.log(jobId, 'info', 'Parsing user shopping preferences with AI');
        parsedPreferences = await this.aiAssistant.parseUserPreferences(userPreferences);
        await this.log(jobId, 'info', `Preferences parsed: ${JSON.stringify(parsedPreferences.global)}`);
      }

      browser = await this.launchBrowser();
      const page = await browser.newPage();

      await page.setViewport({ width: 1920, height: 1080 });
      await page.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      );

      await this.log(jobId, 'info', 'Navigating to Walmart.com');
      await page.goto('https://www.walmart.com', {
        waitUntil: 'networkidle2',
        timeout: 30000
      });

      await this.randomDelay(2000, 4000);

      let addedCount = 0;
      const selectedProducts = [];

      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        await this.log(jobId, 'info', `Processing item ${i + 1}/${items.length}: ${item.name}`);

        try {
          // Search and get multiple results
          const searchResults = await this.searchProduct(page, item, jobId);

          if (searchResults.length === 0) {
            await this.log(jobId, 'warning', `No results found for ${item.name}`);
            continue;
          }

          // Use AI to select best product
          let selectedProduct;
          if (process.env.OPENAI_API_KEY && searchResults.length > 1) {
            await this.log(jobId, 'info', `AI analyzing ${searchResults.length} options for ${item.name}`);

            const aiSelection = await this.aiAssistant.selectBestProduct(
              item,
              searchResults,
              userPreferences
            );

            selectedProduct = aiSelection.selectedProduct;
            await this.log(jobId, 'info',
              `AI selected: ${selectedProduct.title} (Score: ${aiSelection.matchScore}/100) - ${aiSelection.reasoning}`
            );

            if (aiSelection.warnings.length > 0) {
              await this.log(jobId, 'warning', `Warnings: ${aiSelection.warnings.join(', ')}`);
            }
          } else {
            // Fallback: use first result
            selectedProduct = searchResults[0];
            await this.log(jobId, 'info', `Using first result: ${selectedProduct.title}`);
          }

          // Add selected product to cart
          const added = await this.addProductToCart(page, selectedProduct, item.quantity, jobId);

          if (added) {
            addedCount++;
            selectedProducts.push({
              requested: item.name,
              selected: selectedProduct.title,
              price: selectedProduct.price,
              reasoning: selectedProduct.reasoning || 'First result'
            });
          }

        } catch (error) {
          await this.log(jobId, 'warning', `Failed to add ${item.name}: ${error.message}`);
        }

        if (i < items.length - 1) {
          await this.randomDelay(2000, 5000);
        }
      }

      if (addedCount === 0) {
        throw new Error('Failed to add any items to cart');
      }

      await this.log(jobId, 'info', `Successfully added ${addedCount}/${items.length} items with AI selection`);

      // Navigate to cart
      await page.goto('https://www.walmart.com/cart', {
        waitUntil: 'networkidle2',
        timeout: 30000
      });

      const cartUrl = page.url();

      await this.updateJobStatus(jobId, 'completed', {
        shareUrl: cartUrl,
        completedAt: Date.now(),
        metadata: JSON.stringify({ selectedProducts })
      });

      await this.db.incrementUserJobCount(userId, true);
      await this.log(jobId, 'info', 'Cart creation completed successfully');

      return {
        success: true,
        shareUrl: cartUrl,
        itemsAdded: addedCount,
        selectedProducts
      };

    } catch (error) {
      await this.log(jobId, 'error', `Cart creation failed: ${error.message}`);
      await this.updateJobStatus(jobId, 'failed', {
        errorMessage: error.message,
        completedAt: Date.now()
      });
      await this.db.incrementUserJobCount(userId, false);
      return { success: false, error: error.message };
    } finally {
      if (browser) {
        await browser.close();
      }
    }
  }

  /**
   * Search for product and extract top results with metadata
   */
  async searchProduct(page, item, jobId) {
    try {
      // Type search query
      const searchSelector = 'input[aria-label="Search"]';
      await page.waitForSelector(searchSelector, { timeout: 10000 });

      await page.click(searchSelector, { clickCount: 3 });
      await page.keyboard.press('Backspace');
      await page.type(searchSelector, item.name, { delay: 100 });
      await this.randomDelay(500, 1000);
      await page.keyboard.press('Enter');

      // Wait for results to load
      await this.randomDelay(3000, 5000);

      // Extract product data from search results
      const products = await page.evaluate(() => {
        const results = [];
        const productCards = document.querySelectorAll('[data-item-id], [data-product-id], .search-result-gridview-item, article');

        productCards.forEach((card, index) => {
          if (index >= 10) return; // Limit to top 10 results

          try {
            const titleEl = card.querySelector('[data-automation-id="product-title"], h1, h2, h3, [class*="title"]');
            const priceEl = card.querySelector('[data-automation-id="product-price"], [class*="price"], .price-main');
            const ratingEl = card.querySelector('[class*="rating"], .stars');
            const imageEl = card.querySelector('img');
            const badgeEls = card.querySelectorAll('[class*="badge"], [class*="label"]');

            if (!titleEl) return;

            const title = titleEl.textContent.trim();
            const price = priceEl ? priceEl.textContent.trim() : 'Price unavailable';
            const rating = ratingEl ? ratingEl.getAttribute('aria-label') || ratingEl.textContent.trim() : 'N/A';
            const imageUrl = imageEl ? imageEl.src : null;
            const badges = Array.from(badgeEls).map(b => b.textContent.trim());

            // Extract additional metadata
            const descriptionEl = card.querySelector('[class*="description"], .product-description');
            const brandEl = card.querySelector('[class*="brand"]');
            const sizeEl = card.querySelector('[class*="size"], [class*="weight"]');

            results.push({
              title,
              price,
              rating,
              imageUrl,
              badges,
              description: descriptionEl ? descriptionEl.textContent.trim() : '',
              brand: brandEl ? brandEl.textContent.trim() : '',
              size: sizeEl ? sizeEl.textContent.trim() : '',
              element: null // We'll click later by index
            });
          } catch (e) {
            console.error('Error extracting product data:', e);
          }
        });

        return results;
      });

      await this.log(jobId, 'info', `Found ${products.length} products for ${item.name}`);
      return products;

    } catch (error) {
      await this.log(jobId, 'error', `Search failed: ${error.message}`);
      return [];
    }
  }

  /**
   * Add specific product to cart by clicking its add button
   */
  async addProductToCart(page, product, quantity, jobId) {
    try {
      // Find and click the product by title
      const clicked = await page.evaluate((productTitle) => {
        const links = Array.from(document.querySelectorAll('a, [role="link"]'));
        const productLink = links.find(link =>
          link.textContent.includes(productTitle.substring(0, 30))
        );

        if (productLink) {
          productLink.click();
          return true;
        }
        return false;
      }, product.title);

      if (!clicked) {
        throw new Error('Could not find product link');
      }

      // Wait for product page to load
      await this.randomDelay(2000, 3000);

      // Find and click "Add to cart"
      const addToCartSelectors = [
        'button[data-automation-id="add-to-cart"]',
        'button[aria-label*="Add to cart"]',
        'button:has-text("Add to cart")'
      ];

      let added = false;
      for (const selector of addToCartSelectors) {
        try {
          const button = await page.$(selector);
          if (button) {
            await button.click();
            added = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!added) {
        throw new Error('Could not find Add to Cart button');
      }

      await this.randomDelay(1000, 2000);

      // Set quantity if needed
      if (quantity && quantity > 1) {
        await this.setQuantity(page, quantity);
      }

      await this.log(jobId, 'info', `Added ${product.title} to cart`);
      return true;

    } catch (error) {
      await this.log(jobId, 'error', `Failed to add product: ${error.message}`);
      return false;
    }
  }

  async setQuantity(page, quantity) {
    // Quantity setting logic (same as before)
    const quantitySelectors = [
      'input[data-automation-id="quantity-input"]',
      'input[aria-label*="Quantity"]',
      'select[data-automation-id="quantity-select"]'
    ];

    for (const selector of quantitySelectors) {
      try {
        const element = await page.$(selector);
        if (element) {
          const tagName = await element.evaluate(el => el.tagName.toLowerCase());
          if (tagName === 'select') {
            await page.select(selector, quantity.toString());
          } else {
            await element.click({ clickCount: 3 });
            await page.keyboard.press('Backspace');
            await element.type(quantity.toString());
          }
          await this.randomDelay(500, 1000);
          return true;
        }
      } catch (e) {
        continue;
      }
    }
    return false;
  }

  async launchBrowser() {
    const args = [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--disable-gpu',
      '--window-size=1920,1080'
    ];

    if (this.proxyConfig) {
      args.push(`--proxy-server=${this.proxyConfig.host}:${this.proxyConfig.port}`);
    }

    const launchOptions = {
      headless: 'new',
      args,
      defaultViewport: null
    };

    if (process.env.PUPPETEER_EXECUTABLE_PATH) {
      launchOptions.executablePath = process.env.PUPPETEER_EXECUTABLE_PATH;
    }

    return await puppeteer.launch(launchOptions);
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

  randomDelay(min, max) {
    const delay = Math.floor(Math.random() * (max - min + 1)) + min;
    return new Promise(resolve => setTimeout(resolve, delay));
  }
}

module.exports = SmartWalmartCartService;
