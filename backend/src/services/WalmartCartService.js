const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

// Use stealth plugin to avoid detection
puppeteer.use(StealthPlugin());

class WalmartCartService {
  constructor(database, logger) {
    this.db = database;
    this.logger = logger;
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

  async createCart(jobId, items, userId) {
    let browser;

    try {
      await this.log(jobId, 'info', 'Starting cart creation');
      await this.updateJobStatus(jobId, 'processing');

      // Launch browser
      browser = await this.launchBrowser();
      const page = await browser.newPage();

      // Set realistic viewport and user agent
      await page.setViewport({ width: 1920, height: 1080 });
      await page.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      );

      // Navigate to Walmart
      await this.log(jobId, 'info', 'Navigating to Walmart.com');
      await page.goto('https://www.walmart.com', {
        waitUntil: 'networkidle2',
        timeout: 30000
      });

      // Wait a bit to appear human-like
      await this.randomDelay(2000, 4000);

      // Process each item
      let addedCount = 0;
      for (let i = 0; i < items.length; i++) {
        const item = items[i];
        await this.log(jobId, 'info', `Processing item ${i + 1}/${items.length}: ${item.name}`);

        try {
          const added = await this.addItemToCart(page, item, jobId);
          if (added) addedCount++;
        } catch (error) {
          await this.log(jobId, 'warning', `Failed to add ${item.name}: ${error.message}`);
        }

        // Random delay between items to appear human-like
        if (i < items.length - 1) {
          await this.randomDelay(2000, 5000);
        }
      }

      if (addedCount === 0) {
        throw new Error('Failed to add any items to cart');
      }

      await this.log(jobId, 'info', `Successfully added ${addedCount}/${items.length} items`);

      // Navigate to cart
      await this.log(jobId, 'info', 'Opening cart');
      await page.goto('https://www.walmart.com/cart', {
        waitUntil: 'networkidle2',
        timeout: 30000
      });

      await this.randomDelay(1000, 2000);

      // Try to get shareable cart URL
      const shareUrl = await this.getShareableCartUrl(page, jobId);

      if (!shareUrl) {
        // If share feature not available, just use direct cart URL
        const cartUrl = page.url();
        await this.log(jobId, 'warning', 'Share button not found, using direct cart URL');

        await this.updateJobStatus(jobId, 'completed', {
          shareUrl: cartUrl,
          completedAt: Date.now()
        });

        await this.db.incrementUserJobCount(userId, true);
        await this.sendWebhook(userId, jobId, cartUrl, addedCount);

        return { success: true, shareUrl: cartUrl, itemsAdded: addedCount };
      }

      // Update job as completed
      await this.updateJobStatus(jobId, 'completed', {
        shareUrl: shareUrl,
        completedAt: Date.now()
      });

      await this.db.incrementUserJobCount(userId, true);
      await this.log(jobId, 'info', 'Cart creation completed successfully');

      // Send webhook notification
      await this.sendWebhook(userId, jobId, shareUrl, addedCount);

      return { success: true, shareUrl, itemsAdded: addedCount };

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

  async launchBrowser() {
    const args = [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-accelerated-2d-canvas',
      '--disable-gpu',
      '--window-size=1920,1080'
    ];

    // Add proxy if configured
    if (this.proxyConfig) {
      args.push(`--proxy-server=${this.proxyConfig.host}:${this.proxyConfig.port}`);
    }

    const launchOptions = {
      headless: 'new',
      args,
      defaultViewport: null
    };

    // Use custom Chrome/Chromium path if specified
    if (process.env.PUPPETEER_EXECUTABLE_PATH) {
      launchOptions.executablePath = process.env.PUPPETEER_EXECUTABLE_PATH;
    }

    return await puppeteer.launch(launchOptions);
  }

  async addItemToCart(page, item, jobId) {
    try {
      // Find and click search box
      const searchSelector = 'input[aria-label="Search"]';
      await page.waitForSelector(searchSelector, { timeout: 10000 });

      // Clear search box
      await page.click(searchSelector, { clickCount: 3 });
      await page.keyboard.press('Backspace');

      // Type item name
      await page.type(searchSelector, item.name, { delay: 100 });

      // Wait a bit before pressing enter
      await this.randomDelay(500, 1000);

      // Press Enter to search
      await page.keyboard.press('Enter');

      // Wait for search results
      await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 15000 });

      await this.randomDelay(1000, 2000);

      // Find first "Add to cart" button
      const addToCartSelectors = [
        'button[data-automation-id="add-to-cart"]',
        'button[aria-label*="Add to cart"]',
        'button:has-text("Add to cart")',
        'button[data-testid="add-to-cart"]'
      ];

      let addButton = null;
      for (const selector of addToCartSelectors) {
        try {
          addButton = await page.$(selector);
          if (addButton) break;
        } catch (e) {
          continue;
        }
      }

      if (!addButton) {
        // Try to click the first product to go to product page
        const productSelectors = [
          'div[data-automation-id="product-title"]',
          'a[link-identifier="product-title"]',
          'span[data-automation-id="product-title"]'
        ];

        let productLink = null;
        for (const selector of productSelectors) {
          try {
            productLink = await page.$(selector);
            if (productLink) {
              await productLink.click();
              await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 10000 });
              await this.randomDelay(1000, 2000);

              // Try to find add to cart button on product page
              for (const selector of addToCartSelectors) {
                try {
                  addButton = await page.$(selector);
                  if (addButton) break;
                } catch (e) {
                  continue;
                }
              }
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (!addButton) {
        throw new Error('Could not find "Add to cart" button');
      }

      // Click add to cart
      await addButton.click();
      await this.randomDelay(1000, 2000);

      // Handle quantity if needed
      if (item.quantity && item.quantity > 1) {
        try {
          await this.setQuantity(page, item.quantity);
        } catch (e) {
          await this.log(jobId, 'warning', `Could not set quantity for ${item.name}: ${e.message}`);
        }
      }

      await this.log(jobId, 'info', `Successfully added ${item.name} to cart`);
      return true;

    } catch (error) {
      await this.log(jobId, 'warning', `Failed to add ${item.name}: ${error.message}`);
      return false;
    }
  }

  async setQuantity(page, quantity) {
    const quantitySelectors = [
      'input[data-automation-id="quantity-input"]',
      'input[aria-label*="Quantity"]',
      'select[data-automation-id="quantity-select"]'
    ];

    for (const selector of quantitySelectors) {
      try {
        const element = await page.$(selector);
        if (element) {
          // Check if it's a select or input
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

  async getShareableCartUrl(page, jobId) {
    try {
      // Look for share button
      const shareSelectors = [
        'button[data-automation-id="share-cart"]',
        'button[aria-label*="Share"]',
        'button:has-text("Share cart")'
      ];

      let shareButton = null;
      for (const selector of shareSelectors) {
        try {
          shareButton = await page.$(selector);
          if (shareButton) break;
        } catch (e) {
          continue;
        }
      }

      if (!shareButton) {
        await this.log(jobId, 'warning', 'Share button not found');
        return null;
      }

      // Click share button
      await shareButton.click();
      await this.randomDelay(1000, 2000);

      // Look for share URL input/display
      const urlSelectors = [
        'input[data-automation-id="share-url"]',
        'input[aria-label*="Share link"]',
        '.share-url',
        '[data-testid="share-url"]'
      ];

      for (const selector of urlSelectors) {
        try {
          const urlElement = await page.$(selector);
          if (urlElement) {
            const shareUrl = await urlElement.evaluate(el => {
              return el.value || el.textContent || el.innerText;
            });

            if (shareUrl && shareUrl.includes('walmart.com')) {
              await this.log(jobId, 'info', 'Found shareable cart URL');
              return shareUrl.trim();
            }
          }
        } catch (e) {
          continue;
        }
      }

      return null;

    } catch (error) {
      await this.log(jobId, 'warning', `Error getting shareable URL: ${error.message}`);
      return null;
    }
  }

  async sendWebhook(userId, jobId, shareUrl, itemsAdded) {
    try {
      const job = await this.db.getCartJob(jobId);

      if (!job.webhook_url) {
        return; // No webhook configured
      }

      const axios = require('axios');

      await axios.post(job.webhook_url, {
        event: 'cart_completed',
        jobId,
        userId,
        shareUrl,
        itemsAdded,
        timestamp: Date.now()
      }, {
        headers: {
          'Content-Type': 'application/json',
          'X-Webhook-Secret': process.env.WEBHOOK_SECRET
        },
        timeout: 10000
      });

      await this.db.updateCartJob(jobId, {
        webhook_delivered: 1,
        updated_at: Date.now()
      });

      await this.log(jobId, 'info', 'Webhook delivered successfully');

    } catch (error) {
      await this.log(jobId, 'warning', `Webhook delivery failed: ${error.message}`);
    }
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

module.exports = WalmartCartService;
