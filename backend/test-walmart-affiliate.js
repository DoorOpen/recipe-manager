require('dotenv').config();
const axios = require('axios');

/**
 * Test Walmart Affiliate API
 * Simple API key authentication - no RSA signatures needed!
 */

const PUBLISHER_ID = process.env.WALMART_PUBLISHER_ID;
const API_KEY = process.env.WALMART_API_KEY;

// Affiliate API endpoint
const BASE_URL = 'https://api.walmartlabs.com/v1';

async function testProductSearch(query = 'organic tomatoes') {
  console.log('\n🔍 Testing Walmart Affiliate Product Search...\n');

  const url = `${BASE_URL}/search`;

  console.log('Request Details:');
  console.log('  URL:', url);
  console.log('  Query:', query);
  console.log('  Publisher ID:', PUBLISHER_ID || '❌ NOT SET');
  console.log('  API Key:', API_KEY ? '***' + API_KEY.slice(-4) : '❌ NOT SET');
  console.log('\n');

  try {
    const response = await axios.get(url, {
      params: {
        query: query,
        numItems: 5,
        publisherId: PUBLISHER_ID,
        apiKey: API_KEY,
        format: 'json'
      },
      timeout: 10000
    });

    console.log('✅ Search Successful!\n');
    console.log('Status:', response.status, response.statusText);
    console.log('Products Found:', response.data.items?.length || 0);
    console.log('\n');

    if (response.data.items && response.data.items.length > 0) {
      console.log('Sample Products:\n');
      response.data.items.slice(0, 3).forEach((item, index) => {
        console.log(`${index + 1}. ${item.name}`);
        console.log(`   Price: $${item.salePrice}`);
        console.log(`   Item ID: ${item.itemId}`);
        console.log(`   Add to Cart: ${item.addToCartUrl || 'N/A'}`);
        if (item.customerRating) {
          console.log(`   Rating: ${item.customerRating}/5 (${item.numReviews} reviews)`);
        }
        console.log('');
      });
    }

    return { success: true, data: response.data };

  } catch (error) {
    console.error('❌ Search Failed!\n');

    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Error:', error.response.data);

      if (error.response.status === 403) {
        console.error('\n⚠️  Authentication Error:');
        console.error('  - Invalid API key or Publisher ID');
        console.error('  - Check credentials at: https://affiliates.walmart.com/');
      } else if (error.response.status === 400) {
        console.error('\n⚠️  Bad Request:');
        console.error('  - Check that all required parameters are correct');
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
  console.log('\n🔍 Testing Walmart Item Lookup...\n');

  const url = `${BASE_URL}/items/${itemId}`;

  console.log('Request Details:');
  console.log('  URL:', url);
  console.log('  Item ID:', itemId);
  console.log('\n');

  try {
    const response = await axios.get(url, {
      params: {
        publisherId: PUBLISHER_ID,
        apiKey: API_KEY,
        format: 'json'
      },
      timeout: 10000
    });

    console.log('✅ Item Lookup Successful!\n');
    console.log('Product Details:');
    console.log('  Name:', response.data.name);
    console.log('  Price: $' + response.data.salePrice);
    console.log('  Brand:', response.data.brandName || 'N/A');
    console.log('  Stock:', response.data.stock || 'N/A');
    console.log('  Rating:', response.data.customerRating || 'N/A');
    console.log('  Add to Cart:', response.data.addToCartUrl || 'N/A');
    console.log('\n');

    return { success: true, data: response.data };

  } catch (error) {
    console.error('❌ Item Lookup Failed!\n');
    console.error('Error:', error.response?.data || error.message);
    return { success: false, error: error.message };
  }
}

async function testCartUrl(itemIds = ['49624906', '10534875']) {
  console.log('\n🛒 Testing Cart URL Generation...\n');

  // Affiliate cart URL format: items with quantities
  // Format: itemId:quantity,itemId:quantity
  const cartItems = itemIds.map(id => `${id}:1`).join(',');
  const cartUrl = `https://walmart.com/cart/addToCart?items=${cartItems}`;

  console.log('Generated Cart URL:');
  console.log('  ' + cartUrl);
  console.log('\n');
  console.log('✅ Cart URL generated successfully!');
  console.log('\nYou can open this URL to add items to cart.');
  console.log('This is the URL you would send back to the Flutter app.\n');

  return { success: true, url: cartUrl };
}

async function runTests() {
  console.log('\n╔════════════════════════════════════════════╗');
  console.log('║   Walmart Affiliate API Test              ║');
  console.log('╚════════════════════════════════════════════╝\n');

  console.log('Configuration:');
  console.log('  Publisher ID:', PUBLISHER_ID || '❌ NOT SET');
  console.log('  API Key:', API_KEY ? '✅ SET' : '❌ NOT SET');
  console.log('  Base URL:', BASE_URL);
  console.log('');

  if (!PUBLISHER_ID || !API_KEY) {
    console.error('❌ Missing Affiliate API credentials!\n');
    console.error('To get your credentials:');
    console.error('  1. Go to: https://affiliates.walmart.com/');
    console.error('  2. Sign up or login');
    console.error('  3. Navigate to "API" or "Developer Tools"');
    console.error('  4. Copy your Publisher ID and API Key');
    console.error('  5. Add to backend/.env:');
    console.error('');
    console.error('     WALMART_PUBLISHER_ID=your-publisher-id');
    console.error('     WALMART_API_KEY=your-api-key');
    console.error('');
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

  // Test 3: Cart URL Generation
  if (searchResult.success && searchResult.data?.items?.length > 0) {
    const itemIds = searchResult.data.items.slice(0, 2).map(item => item.itemId.toString());
    await testCartUrl(itemIds);
  }

  console.log('─'.repeat(50));
  console.log('\n✅ All tests completed!\n');
}

// Run tests
runTests().catch(error => {
  console.error('\n💥 Test failed:', error);
  process.exit(1);
});
