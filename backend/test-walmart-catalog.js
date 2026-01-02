require('dotenv').config();
const crypto = require('crypto');
const fs = require('fs');
const axios = require('axios');

/**
 * Test Walmart Catalog Product API
 * Uses RSA signature authentication + Publisher ID
 */

const CONSUMER_ID = process.env.WALMART_CONSUMER_ID;
const PRIVATE_KEY_PATH = process.env.WALMART_PRIVATE_KEY_PATH;
const KEY_VERSION = process.env.WALMART_KEY_VERSION || '1';
const API_ENV = process.env.WALMART_API_ENV || 'stage';
const PUBLISHER_ID = process.env.WALMART_PUBLISHER_ID || '';

// API URLs
const API_URLS = {
  stage: 'https://developer.api.walmart.com',
  prod: 'https://api.walmart.com'
};

function generateSignature(consumerId, privateKeyPath, timestamp) {
  try {
    const privateKey = fs.readFileSync(privateKeyPath, 'utf8');
    const stringToSign = consumerId + '\n' + timestamp + '\n';

    const sign = crypto.createSign('RSA-SHA256');
    sign.update(stringToSign);
    sign.end();

    return sign.sign(privateKey, 'base64');
  } catch (error) {
    console.error('Error generating signature:', error.message);
    throw error;
  }
}

async function testCatalogProducts(options = {}) {
  console.log('\n🔍 Testing Walmart Catalog Product API...\n');

  const timestamp = Date.now().toString();
  const signature = generateSignature(CONSUMER_ID, PRIVATE_KEY_PATH, timestamp);

  const baseUrl = API_URLS[API_ENV];
  const endpoint = '/api-proxy/service/affil/product/v2/paginated/items';
  const url = `${baseUrl}${endpoint}`;

  // Build query parameters
  const params = {
    publisherId: PUBLISHER_ID,
    count: options.count || 10,
    format: 'json'
  };

  // Add optional filters
  if (options.category) params.category = options.category;
  if (options.brand) params.brand = options.brand;
  if (options.specialOffer) params.specialOffer = options.specialOffer;
  if (options.soldByWmt) params.soldByWmt = true;
  if (options.available) params.available = true;

  console.log('Request Details:');
  console.log('  URL:', url);
  console.log('  Consumer ID:', CONSUMER_ID);
  console.log('  Publisher ID:', PUBLISHER_ID || 'Not set (optional)');
  console.log('  Timestamp:', timestamp);
  console.log('  Filters:', JSON.stringify(params, null, 2));
  console.log('\n');

  try {
    const response = await axios.get(url, {
      params,
      headers: {
        'WM_CONSUMER.ID': CONSUMER_ID,
        'WM_SEC.KEY_VERSION': KEY_VERSION,
        'WM_CONSUMER.INTIMESTAMP': timestamp,
        'WM_SEC.AUTH_SIGNATURE': signature,
        'Accept': 'application/json'
      },
      timeout: 30000
    });

    console.log('✅ Catalog API Successful!\n');
    console.log('Status:', response.status, response.statusText);
    console.log('Total Pages:', response.data.totalPages);
    console.log('Next Page Exists:', response.data.nextPageExist);
    console.log('Items in Response:', response.data.items?.length || 0);
    console.log('\n');

    if (response.data.items && response.data.items.length > 0) {
      console.log('Sample Products:\n');
      response.data.items.slice(0, 3).forEach((item, index) => {
        console.log(`${index + 1}. ${item.name}`);
        console.log(`   Item ID: ${item.itemId}`);
        console.log(`   Price: $${item.salePrice} (MSRP: $${item.msrp})`);
        console.log(`   Brand: ${item.brandName || 'N/A'}`);
        console.log(`   Category: ${item.categoryPath || 'N/A'}`);
        console.log(`   Stock: ${item.stock || 'N/A'}`);
        if (item.customerRating) {
          console.log(`   Rating: ${item.customerRating}/5 (${item.numReviews} reviews)`);
        }
        if (item.affiliateAddToCartUrl) {
          console.log(`   🛒 Add to Cart URL: ${item.affiliateAddToCartUrl.substring(0, 60)}...`);
        }
        console.log(`   Available Online: ${item.availableOnline}`);
        console.log(`   Fulfilled by Walmart: ${item.fulfilledByWalmart || false}`);
        console.log('');
      });

      // Show cart URL example
      if (response.data.items[0].affiliateAddToCartUrl) {
        console.log('💡 Cart URL Example:');
        console.log('   You can use affiliateAddToCartUrl to add items to cart!');
        console.log('   This URL includes your Publisher ID for commission tracking.\n');
      }
    }

    if (response.data.nextPage) {
      console.log('📄 Next Page Available:');
      console.log('   Path:', response.data.nextPage);
      console.log('   Use this to fetch the next batch of items.\n');
    }

    return { success: true, data: response.data };

  } catch (error) {
    console.error('❌ Catalog API Failed!\n');

    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Error:', error.response.data);

      if (error.response.status === 401) {
        console.error('\nTroubleshooting:');
        console.error('  1. Verify Consumer ID is correct');
        console.error('  2. Check that public key was uploaded to Walmart');
        console.error('  3. Ensure private key matches uploaded public key');
        console.error('  4. Wait for staging approval (2-5 business days)');
      } else if (error.response.status === 403) {
        console.error('\nTroubleshooting:');
        console.error('  1. Check that your subscription includes Catalog API access');
        console.error('  2. Verify Publisher ID is correct (if using affiliate features)');
      }
    } else if (error.request) {
      console.error('Network Error:', error.message);
    } else {
      console.error('Error:', error.message);
    }

    return { success: false, error: error.message };
  }
}

async function testProductSearch(query = 'organic tomatoes') {
  console.log('\n🔍 Testing Product Search API...\n');

  const timestamp = Date.now().toString();
  const signature = generateSignature(CONSUMER_ID, PRIVATE_KEY_PATH, timestamp);

  const baseUrl = API_URLS[API_ENV];
  const endpoint = '/api-proxy/service/affil/product/v2/search';
  const url = `${baseUrl}${endpoint}`;

  console.log('Request Details:');
  console.log('  URL:', url);
  console.log('  Query:', query);
  console.log('\n');

  try {
    const response = await axios.get(url, {
      params: {
        query: query,
        numItems: 5,
        publisherId: PUBLISHER_ID,
        format: 'json'
      },
      headers: {
        'WM_CONSUMER.ID': CONSUMER_ID,
        'WM_SEC.KEY_VERSION': KEY_VERSION,
        'WM_CONSUMER.INTIMESTAMP': timestamp,
        'WM_SEC.AUTH_SIGNATURE': signature,
        'Accept': 'application/json'
      },
      timeout: 10000
    });

    console.log('✅ Search Successful!\n');
    console.log('Products Found:', response.data.items?.length || 0);
    console.log('\n');

    if (response.data.items && response.data.items.length > 0) {
      console.log('Sample Products:\n');
      response.data.items.slice(0, 3).forEach((item, index) => {
        console.log(`${index + 1}. ${item.name}`);
        console.log(`   Price: $${item.salePrice}`);
        console.log(`   Item ID: ${item.itemId}`);
        if (item.affiliateAddToCartUrl) {
          console.log(`   🛒 Cart URL available`);
        }
        console.log('');
      });
    }

    return { success: true, data: response.data };

  } catch (error) {
    console.error('❌ Search Failed!\n');
    console.error('Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

async function runTests() {
  console.log('\n╔════════════════════════════════════════════╗');
  console.log('║   Walmart Catalog Product API Test        ║');
  console.log('╚════════════════════════════════════════════╝\n');

  console.log('Configuration:');
  console.log('  Consumer ID:', CONSUMER_ID || '❌ NOT SET');
  console.log('  Private Key:', PRIVATE_KEY_PATH || '❌ NOT SET');
  console.log('  Publisher ID:', PUBLISHER_ID || '(Optional - for affiliate links)');
  console.log('  Key Version:', KEY_VERSION);
  console.log('  Environment:', API_ENV);
  console.log('');

  if (!CONSUMER_ID || !PRIVATE_KEY_PATH) {
    console.error('❌ Missing configuration!');
    console.error('\nRequired in .env:');
    console.error('  WALMART_CONSUMER_ID=your-consumer-id');
    console.error('  WALMART_PRIVATE_KEY_PATH=./keys/WM_IO_private_key.pem');
    console.error('\nOptional (for affiliate features):');
    console.error('  WALMART_PUBLISHER_ID=your-impact-radius-publisher-id');
    process.exit(1);
  }

  if (!fs.existsSync(PRIVATE_KEY_PATH)) {
    console.error(`❌ Private key not found at: ${PRIVATE_KEY_PATH}`);
    process.exit(1);
  }

  console.log('─'.repeat(50));

  // Test 1: Product Search
  console.log('\n📦 TEST 1: Product Search\n');
  const searchResult = await testProductSearch('organic tomatoes');

  console.log('─'.repeat(50));

  // Test 2: Catalog with Electronics Category
  console.log('\n📦 TEST 2: Catalog - Electronics (Category 3944)\n');
  await testCatalogProducts({
    category: '3944',
    count: 5,
    available: true
  });

  console.log('─'.repeat(50));

  // Test 3: Catalog with Brand Filter
  console.log('\n📦 TEST 3: Catalog - Great Value Brand\n');
  await testCatalogProducts({
    brand: 'Great Value',
    count: 5,
    available: true,
    soldByWmt: true
  });

  console.log('─'.repeat(50));
  console.log('\n✅ All tests completed!\n');

  if (!PUBLISHER_ID) {
    console.log('💡 Note: To get affiliate cart URLs and commissions:');
    console.log('   1. Sign up at: https://impact.com/');
    console.log('   2. Join Walmart Affiliate Program');
    console.log('   3. Get your Publisher ID');
    console.log('   4. Add to .env: WALMART_PUBLISHER_ID=your-publisher-id');
    console.log('');
  }
}

// Run tests
runTests().catch(error => {
  console.error('\n💥 Test failed:', error);
  process.exit(1);
});
