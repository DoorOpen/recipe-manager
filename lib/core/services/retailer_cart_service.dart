import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Retailer cart capabilities
enum CartCapability {
  fullApi,        // Can add items via API (e.g., Instacart Connect)
  deepLink,       // Can use deep linking with cart params
  searchOnly,     // Can only open search page
}

/// Service for populating shopping carts at various retailers
/// Handles API integrations with Instacart, Walmart, and other grocery services
class RetailerCartService {
  // API Configuration - These would be stored securely in environment variables
  static const String? _instacartApiKey = null; // Set via environment or config
  static const String? _walmartAffiliateId = null; // Set via environment or config

  /// Retailer configuration
  static const Map<String, Map<String, dynamic>> retailerConfig = {
    'instacart': {
      'name': 'Instacart',
      'capability': CartCapability.fullApi,
      'requiresAuth': true,
      'supportsDirect': true,
    },
    'walmart': {
      'name': 'Walmart',
      'capability': CartCapability.deepLink,
      'requiresAuth': false,
      'supportsDirect': false,
    },
    'amazon': {
      'name': 'Amazon Fresh',
      'capability': CartCapability.searchOnly,
      'requiresAuth': true,
      'supportsDirect': false,
    },
  };

  /// Check if API keys are configured
  bool get hasInstacartApiKey => _instacartApiKey != null && _instacartApiKey!.isNotEmpty;
  bool get hasWalmartAffiliateId => _walmartAffiliateId != null && _walmartAffiliateId!.isNotEmpty;

  /// Add items to Instacart cart via API
  /// Requires Instacart Connect partnership
  Future<InstacartCartResult> addToInstacartCart(
    List<GroceryItem> items, {
    String? storeId,
    String? zipCode,
  }) async {
    if (!hasInstacartApiKey) {
      return InstacartCartResult(
        success: false,
        message: 'Instacart API key not configured. Please set up Instacart Connect partnership.',
      );
    }

    try {
      // Instacart Connect API endpoint (example)
      const apiUrl = 'https://connect.instacart.com/v2/carts';

      final headers = {
        'Authorization': 'Bearer $_instacartApiKey',
        'Content-Type': 'application/json',
      };

      // Build cart payload
      final cartItems = items.map((item) => {
        'name': item.name,
        'quantity': item.quantity ?? 1,
        'unit': item.unit,
      }).toList();

      final body = jsonEncode({
        'items': cartItems,
        'store_id': storeId,
        'zip_code': zipCode ?? '00000',
        'source': 'recipe_manager',
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return InstacartCartResult(
          success: true,
          cartUrl: data['cart_url'] ?? data['checkout_url'],
          cartId: data['cart_id'],
          message: 'Successfully added ${items.length} items to Instacart cart',
        );
      } else {
        return InstacartCartResult(
          success: false,
          message: 'Failed to create cart: ${response.statusCode}',
        );
      }
    } catch (e) {
      return InstacartCartResult(
        success: false,
        message: 'Error: $e',
      );
    }
  }

  /// Generate Walmart cart deep link
  /// Uses Walmart's URL parameters to pre-fill search/cart
  String generateWalmartCartLink(List<GroceryItem> items) {
    // Walmart supports adding items via URL parameters (limited)
    // Format: https://www.walmart.com/cart?items=item1,item2,item3

    final itemNames = items.take(10).map((item) {
      final qty = item.quantity?.toInt() ?? 1;
      return '${Uri.encodeComponent(item.name)}:$qty';
    }).join(',');

    return 'https://www.walmart.com/search?q=${Uri.encodeComponent(itemNames)}';
  }

  /// Generate Amazon Fresh list URL
  /// Amazon doesn't support direct cart addition via public API
  String generateAmazonFreshLink(List<GroceryItem> items) {
    if (items.isEmpty) return 'https://www.amazon.com/alm/storefront';

    final searchQuery = items.first.name;
    return 'https://www.amazon.com/s?k=${Uri.encodeComponent(searchQuery)}&i=amazonfresh';
  }

  /// Create a shareable shopping list for retailers without APIs
  /// This generates a formatted list that can be used with browser extensions
  /// or manually copied into retailer websites
  Map<String, dynamic> generateShoppingListData(
    GroceryList list,
    List<GroceryItem> items,
  ) {
    return {
      'listName': list.name,
      'items': items.map((item) => {
        'name': item.name,
        'quantity': item.quantity,
        'unit': item.unit,
        'category': item.category.name,
      }).toList(),
      'totalItems': items.length,
      'format': 'json',
      'version': '1.0',
    };
  }

  /// Generate browser automation script (for advanced users)
  /// This can be used with browser extensions like Tampermonkey
  String generateAutoFillScript(List<GroceryItem> items, String retailer) {
    final itemsJson = jsonEncode(items.map((item) => {
      'name': item.name,
      'quantity': item.quantity ?? 1,
    }).toList());

    return '''
// Auto-fill shopping cart for $retailer
// Paste this into your browser console while on the retailer website

const items = $itemsJson;

// This is a placeholder - actual implementation would vary by retailer
console.log('Items to add:', items);

// For Walmart
if (window.location.hostname.includes('walmart.com')) {
  items.forEach(async item => {
    console.log('Searching for:', item.name);
    // Add item to cart logic here
  });
}

// For Instacart
if (window.location.hostname.includes('instacart.com')) {
  items.forEach(async item => {
    console.log('Searching for:', item.name);
    // Add item to cart logic here
  });
}
''';
  }
}

/// Result from Instacart cart operation
class InstacartCartResult {
  final bool success;
  final String? cartUrl;
  final String? cartId;
  final String message;

  InstacartCartResult({
    required this.success,
    this.cartUrl,
    this.cartId,
    required this.message,
  });
}

/// Browser extension manifest for auto-cart-fill
/// This would be a separate Chrome/Firefox extension
class BrowserExtensionHelper {
  /// Generate manifest for browser extension
  static Map<String, dynamic> generateManifest() {
    return {
      'manifest_version': 3,
      'name': 'Recipe Manager - Auto Cart Fill',
      'version': '1.0',
      'description': 'Automatically fill shopping carts from Recipe Manager',
      'permissions': [
        'storage',
        'activeTab',
      ],
      'host_permissions': [
        'https://www.instacart.com/*',
        'https://www.walmart.com/*',
        'https://www.amazon.com/*',
        'https://www.target.com/*',
        'https://www.kroger.com/*',
      ],
      'background': {
        'service_worker': 'background.js',
      },
      'content_scripts': [
        {
          'matches': [
            'https://www.instacart.com/*',
            'https://www.walmart.com/*',
          ],
          'js': ['content.js'],
        },
      ],
    };
  }

  /// Generate content script for auto-filling carts
  static String generateContentScript() {
    return '''
// Recipe Manager Browser Extension - Content Script

// Listen for messages from the app
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'fillCart') {
    fillShoppingCart(request.items);
    sendResponse({ success: true });
  }
});

async function fillShoppingCart(items) {
  console.log('Filling cart with items:', items);

  // Detect retailer
  const hostname = window.location.hostname;

  if (hostname.includes('instacart.com')) {
    await fillInstacartCart(items);
  } else if (hostname.includes('walmart.com')) {
    await fillWalmartCart(items);
  } else if (hostname.includes('amazon.com')) {
    await fillAmazonCart(items);
  }
}

async function fillInstacartCart(items) {
  for (const item of items) {
    // Find search box
    const searchBox = document.querySelector('input[type="search"]');
    if (!searchBox) continue;

    // Search for item
    searchBox.value = item.name;
    searchBox.dispatchEvent(new Event('input', { bubbles: true }));

    // Wait for results
    await sleep(1000);

    // Click "Add to cart" button
    const addButton = document.querySelector('button[aria-label*="Add"]');
    if (addButton) addButton.click();

    await sleep(500);
  }
}

async function fillWalmartCart(items) {
  // Similar implementation for Walmart
  for (const item of items) {
    // Walmart-specific selectors and logic
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}
''';
  }
}
