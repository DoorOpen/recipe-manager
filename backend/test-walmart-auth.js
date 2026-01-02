require('dotenv').config();
const crypto = require('crypto');
const fs = require('fs');
const axios = require('axios');

/**
 * Test Walmart API Authentication
 * Verifies RSA signature-based authentication works correctly
 */

const CONSUMER_ID = process.env.WALMART_CONSUMER_ID;
const PRIVATE_KEY_PATH = process.env.WALMART_PRIVATE_KEY_PATH;
const KEY_VERSION = process.env.WALMART_KEY_VERSION || '1';
const API_ENV = process.env.WALMART_API_ENV || 'stage';

// API URLs
const API_URLS = {
  stage: 'https://developer.api.walmart.com',
  prod: 'https://api.walmart.com'
};

function generateSignature(consumerId, privateKeyPath, timestamp) {
  try {
    // Read private key
    const privateKey = fs.readFileSync(privateKeyPath, 'utf8');

    // Create signature input: consumerId + timestamp
    const stringToSign = consumerId + '\n' + timestamp + '\n';

    // Sign with RSA-SHA256
    const sign = crypto.createSign('RSA-SHA256');
    sign.update(stringToSign);
    sign.end();

    const signature = sign.sign(privateKey, 'base64');

    return signature;
  } catch (error) {
    console.error('Error generating signature:', error.message);
    throw error;
  }
}

async function testProductSearch(query = 'tomatoes') {
  console.log('\n🔍 Testing Walmart Product Search API...\n');

  // Generate timestamp (milliseconds)
  const timestamp = Date.now().toString();

  // Generate signature
  const signature = generateSignature(CONSUMER_ID, PRIVATE_KEY_PATH, timestamp);

  // API endpoint
  const baseUrl = API_URLS[API_ENV];
  const endpoint = '/api-proxy/service/affil/product/v2/search';
  const url = `${baseUrl}${endpoint}`;

  console.log('Request Details:');
  console.log('  URL:', url);
  console.log('  Consumer ID:', CONSUMER_ID);
  console.log('  Timestamp:', timestamp);
  console.log('  Environment:', API_ENV);
  console.log('  Query:', query);
  console.log('\n');

  try {
    const response = await axios.get(url, {
      params: {
        query: query,
        numItems: 5,
        format: 'json'
      },
      headers: {
        'WM_CONSUMER.ID': CONSUMER_ID,
        'WM_SEC.KEY_VERSION': KEY_VERSION,
        'WM_CONSUMER.INTIMESTAMP': timestamp,
        'WM_SEC.AUTH_SIGNATURE': signature,
        'Accept': 'application/json'
      }
    });

    console.log('✅ Authentication Successful!\n');
    console.log('Status:', response.status, response.statusText);
    console.log('Products Found:', response.data.items?.length || 0);
    console.log('\n');

    if (response.data.items && response.data.items.length > 0) {
      console.log('Sample Products:\n');
      response.data.items.slice(0, 3).forEach((item, index) => {
        console.log(`${index + 1}. ${item.name}`);
        console.log(`   Price: $${item.salePrice}`);
        console.log(`   Item ID: ${item.itemId}`);
        if (item.customerRating) {
          console.log(`   Rating: ${item.customerRating}/5 (${item.numReviews} reviews)`);
        }
        console.log('');
      });
    }

    return { success: true, data: response.data };

  } catch (error) {
    console.error('❌ Authentication Failed!\n');

    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Error:', error.response.data);

      if (error.response.status === 401) {
        console.error('\nTroubleshooting:');
        console.error('  1. Verify Consumer ID is correct');
        console.error('  2. Check that public key was uploaded correctly');
        console.error('  3. Ensure private key matches uploaded public key');
        console.error('  4. Verify timestamp is current (not too old/new)');
      }
    } else if (error.request) {
      console.error('Network Error:', error.message);
    } else {
      console.error('Error:', error.message);
    }

    return { success: false, error: error.message };
  }
}

async function testItemLookup(itemId = '49624906') {
  console.log('\n🔍 Testing Walmart Item Lookup API...\n');

  const timestamp = Date.now().toString();
  const signature = generateSignature(CONSUMER_ID, PRIVATE_KEY_PATH, timestamp);

  const baseUrl = API_URLS[API_ENV];
  const endpoint = `/api-proxy/service/affil/product/v2/items/${itemId}`;
  const url = `${baseUrl}${endpoint}`;

  console.log('Request Details:');
  console.log('  URL:', url);
  console.log('  Item ID:', itemId);
  console.log('\n');

  try {
    const response = await axios.get(url, {
      params: {
        format: 'json'
      },
      headers: {
        'WM_CONSUMER.ID': CONSUMER_ID,
        'WM_SEC.KEY_VERSION': KEY_VERSION,
        'WM_CONSUMER.INTIMESTAMP': timestamp,
        'WM_SEC.AUTH_SIGNATURE': signature,
        'Accept': 'application/json'
      }
    });

    console.log('✅ Item Lookup Successful!\n');
    console.log('Product Details:');
    console.log('  Name:', response.data.name);
    console.log('  Price: $' + response.data.salePrice);
    console.log('  Brand:', response.data.brandName || 'N/A');
    console.log('  Stock:', response.data.stock || 'N/A');
    console.log('  Rating:', response.data.customerRating || 'N/A');
    console.log('\n');

    return { success: true, data: response.data };

  } catch (error) {
    console.error('❌ Item Lookup Failed!\n');
    console.error('Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

async function runTests() {
  console.log('\n╔════════════════════════════════════════════╗');
  console.log('║   Walmart API Authentication Test         ║');
  console.log('╚════════════════════════════════════════════╝\n');

  console.log('Configuration:');
  console.log('  Consumer ID:', CONSUMER_ID || '❌ NOT SET');
  console.log('  Private Key:', PRIVATE_KEY_PATH || '❌ NOT SET');
  console.log('  Key Version:', KEY_VERSION);
  console.log('  Environment:', API_ENV);
  console.log('');

  if (!CONSUMER_ID || !PRIVATE_KEY_PATH) {
    console.error('❌ Missing configuration!');
    console.error('\nPlease set in .env:');
    console.error('  WALMART_CONSUMER_ID=your-consumer-id');
    console.error('  WALMART_PRIVATE_KEY_PATH=./keys/WM_IO_private_key.pem');
    process.exit(1);
  }

  // Check if private key exists
  if (!fs.existsSync(PRIVATE_KEY_PATH)) {
    console.error(`❌ Private key not found at: ${PRIVATE_KEY_PATH}`);
    console.error('\nGenerate keys with:');
    console.error('  cd backend/keys');
    console.error('  openssl genrsa -out WM_IO_my_rsa_key_pair 2048');
    console.error('  openssl pkcs8 -topk8 -inform PEM -in WM_IO_my_rsa_key_pair -outform PEM -out WM_IO_private_key.pem -nocrypt');
    process.exit(1);
  }

  console.log('─'.repeat(50));

  // Test 1: Product Search
  const searchResult = await testProductSearch('organic tomatoes');

  console.log('─'.repeat(50));

  // Test 2: Item Lookup (if search succeeded)
  if (searchResult.success && searchResult.data?.items?.length > 0) {
    const firstItemId = searchResult.data.items[0].itemId;
    await testItemLookup(firstItemId.toString());
  }

  console.log('─'.repeat(50));
  console.log('\n✅ All tests completed!\n');
}

// Run tests
runTests().catch(error => {
  console.error('\n💥 Test failed:', error);
  process.exit(1);
});
