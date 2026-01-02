import 'package:uuid/uuid.dart';
import '../models/models.dart' as models;
import '../repositories/recipe_repository.dart';

/// Utility class to generate sample recipe data for testing
class SampleData {
  static const _uuid = Uuid();

  /// Insert sample recipes into the database
  static Future<void> insertSampleRecipes(RecipeRepository repository) async {
    final sampleRecipes = _generateSampleRecipes();

    for (final recipe in sampleRecipes) {
      await repository.insertRecipe(recipe);
    }
  }

  /// Generate a list of sample recipes
  static List<models.Recipe> _generateSampleRecipes() {
    return [
      // Recipe 1: Classic Pancakes
      models.Recipe(
        id: _uuid.v4(),
        title: 'Fluffy Buttermilk Pancakes',
        ingredients: [
          models.Ingredient(name: 'All-purpose flour', quantity: 2, unit: 'cups'),
          models.Ingredient(name: 'Sugar', quantity: 2, unit: 'tbsp'),
          models.Ingredient(name: 'Baking powder', quantity: 2, unit: 'tsp'),
          models.Ingredient(name: 'Baking soda', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Salt', quantity: 0.5, unit: 'tsp'),
          models.Ingredient(name: 'Buttermilk', quantity: 2, unit: 'cups'),
          models.Ingredient(name: 'Eggs', quantity: 2, unit: 'large'),
          models.Ingredient(name: 'Butter (melted)', quantity: 4, unit: 'tbsp'),
          models.Ingredient(name: 'Vanilla extract', quantity: 1, unit: 'tsp'),
        ],
        directions: [
          'In a large bowl, whisk together flour, sugar, baking powder, baking soda, and salt.',
          'In another bowl, whisk together buttermilk, eggs, melted butter, and vanilla extract.',
          'Pour wet ingredients into dry ingredients and stir until just combined. Don\'t overmix - some lumps are okay.',
          'Heat a griddle or pan over medium heat and lightly grease with butter.',
          'Pour 1/4 cup batter for each pancake. Cook until bubbles form on surface (about 2-3 minutes).',
          'Flip and cook until golden brown on the other side (about 1-2 minutes).',
          'Serve hot with maple syrup, butter, and fresh berries.',
        ],
        categories: ['Breakfast', 'Quick & Easy'],
        prepTimeMinutes: 10,
        cookTimeMinutes: 15,
        servings: 4,
        difficulty: 'Easy',
        rating: 5,
        isFavorite: true,
        hasCooked: true,
        photoUrls: [],
        sourceUrl: 'https://example.com/pancakes',
        notes: 'These are the best pancakes! Kids love them.',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),

      // Recipe 2: Chicken Stir-Fry
      models.Recipe(
        id: _uuid.v4(),
        title: 'Asian Chicken Stir-Fry',
        ingredients: [
          models.Ingredient(name: 'Chicken breast (sliced)', quantity: 1, unit: 'lb'),
          models.Ingredient(name: 'Soy sauce', quantity: 3, unit: 'tbsp'),
          models.Ingredient(name: 'Cornstarch', quantity: 1, unit: 'tbsp'),
          models.Ingredient(name: 'Vegetable oil', quantity: 2, unit: 'tbsp'),
          models.Ingredient(name: 'Garlic (minced)', quantity: 3, unit: 'cloves'),
          models.Ingredient(name: 'Ginger (grated)', quantity: 1, unit: 'tbsp'),
          models.Ingredient(name: 'Bell peppers (mixed)', quantity: 2, unit: 'cups'),
          models.Ingredient(name: 'Broccoli florets', quantity: 2, unit: 'cups'),
          models.Ingredient(name: 'Carrots (sliced)', quantity: 1, unit: 'cup'),
          models.Ingredient(name: 'Oyster sauce', quantity: 2, unit: 'tbsp'),
          models.Ingredient(name: 'Sesame oil', quantity: 1, unit: 'tsp'),
        ],
        directions: [
          'Marinate chicken with 1 tbsp soy sauce and cornstarch for 15 minutes.',
          'Heat 1 tbsp oil in a wok or large pan over high heat. Stir-fry chicken until cooked through. Remove and set aside.',
          'Add remaining oil, then stir-fry garlic and ginger until fragrant (30 seconds).',
          'Add all vegetables and stir-fry for 3-4 minutes until crisp-tender.',
          'Return chicken to the pan. Add remaining soy sauce, oyster sauce, and sesame oil.',
          'Toss everything together for 1-2 minutes until well combined and heated through.',
          'Serve hot over steamed rice.',
        ],
        categories: ['Dinner', 'Asian', 'Quick & Easy'],
        prepTimeMinutes: 20,
        cookTimeMinutes: 15,
        servings: 4,
        difficulty: 'Medium',
        rating: 4,
        isFavorite: true,
        hasCooked: false,
        photoUrls: [],
        notes: 'Great for meal prep! Freezes well.',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),

      // Recipe 3: Chocolate Chip Cookies
      models.Recipe(
        id: _uuid.v4(),
        title: 'Perfect Chocolate Chip Cookies',
        ingredients: [
          models.Ingredient(name: 'Butter (softened)', quantity: 1, unit: 'cup'),
          models.Ingredient(name: 'White sugar', quantity: 0.75, unit: 'cup'),
          models.Ingredient(name: 'Brown sugar', quantity: 0.75, unit: 'cup'),
          models.Ingredient(name: 'Eggs', quantity: 2, unit: 'large'),
          models.Ingredient(name: 'Vanilla extract', quantity: 2, unit: 'tsp'),
          models.Ingredient(name: 'All-purpose flour', quantity: 2.25, unit: 'cups'),
          models.Ingredient(name: 'Baking soda', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Salt', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Chocolate chips', quantity: 2, unit: 'cups'),
        ],
        directions: [
          'Preheat oven to 375°F (190°C).',
          'Cream together butter, white sugar, and brown sugar until fluffy.',
          'Beat in eggs one at a time, then add vanilla.',
          'In a separate bowl, whisk together flour, baking soda, and salt.',
          'Gradually mix dry ingredients into butter mixture.',
          'Fold in chocolate chips.',
          'Drop rounded tablespoons of dough onto ungreased cookie sheets, 2 inches apart.',
          'Bake for 9-11 minutes until golden brown around edges.',
          'Cool on baking sheet for 2 minutes before transferring to wire rack.',
        ],
        categories: ['Dessert', 'Baking'],
        prepTimeMinutes: 15,
        cookTimeMinutes: 11,
        servings: 48,
        difficulty: 'Easy',
        rating: 5,
        isFavorite: true,
        hasCooked: true,
        photoUrls: [],
        sourceUrl: 'https://example.com/cookies',
        notes: 'The secret is using both white and brown sugar!',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),

      // Recipe 4: Caesar Salad
      models.Recipe(
        id: _uuid.v4(),
        title: 'Classic Caesar Salad',
        ingredients: [
          models.Ingredient(name: 'Romaine lettuce', quantity: 2, unit: 'heads'),
          models.Ingredient(name: 'Parmesan cheese (grated)', quantity: 0.5, unit: 'cup'),
          models.Ingredient(name: 'Croutons', quantity: 1, unit: 'cup'),
          models.Ingredient(name: 'Anchovy fillets', quantity: 4, unit: 'pieces'),
          models.Ingredient(name: 'Garlic cloves', quantity: 2, unit: 'cloves'),
          models.Ingredient(name: 'Lemon juice', quantity: 2, unit: 'tbsp'),
          models.Ingredient(name: 'Dijon mustard', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Worcestershire sauce', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Olive oil', quantity: 0.5, unit: 'cup'),
          models.Ingredient(name: 'Black pepper', quantity: 0.5, unit: 'tsp'),
        ],
        directions: [
          'Wash and dry romaine lettuce. Tear into bite-sized pieces.',
          'For dressing: In a blender, combine anchovies, garlic, lemon juice, Dijon mustard, and Worcestershire sauce.',
          'Blend until smooth, then slowly drizzle in olive oil while blending.',
          'Season with black pepper.',
          'In a large bowl, toss lettuce with dressing until well coated.',
          'Add half the Parmesan and toss again.',
          'Top with remaining Parmesan and croutons.',
          'Serve immediately.',
        ],
        categories: ['Salad', 'Lunch', 'Side Dish'],
        prepTimeMinutes: 15,
        cookTimeMinutes: 0,
        servings: 4,
        difficulty: 'Easy',
        rating: 4,
        isFavorite: false,
        hasCooked: false,
        photoUrls: [],
        notes: 'Can add grilled chicken for a heartier meal.',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),

      // Recipe 5: Spaghetti Carbonara
      models.Recipe(
        id: _uuid.v4(),
        title: 'Authentic Spaghetti Carbonara',
        ingredients: [
          models.Ingredient(name: 'Spaghetti', quantity: 1, unit: 'lb'),
          models.Ingredient(name: 'Pancetta or bacon', quantity: 8, unit: 'oz'),
          models.Ingredient(name: 'Eggs', quantity: 4, unit: 'large'),
          models.Ingredient(name: 'Parmesan cheese (grated)', quantity: 1, unit: 'cup'),
          models.Ingredient(name: 'Black pepper', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Salt', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Garlic cloves', quantity: 2, unit: 'cloves'),
        ],
        directions: [
          'Bring a large pot of salted water to boil. Cook spaghetti according to package directions.',
          'While pasta cooks, dice pancetta and cook in a large skillet over medium heat until crispy. Add minced garlic in last minute.',
          'In a bowl, whisk together eggs, Parmesan, and black pepper.',
          'Reserve 1 cup pasta water, then drain pasta.',
          'Remove skillet from heat. Add hot pasta to pancetta and toss.',
          'Quickly add egg mixture while tossing constantly. The residual heat will cook the eggs.',
          'Add pasta water a little at a time to create a creamy sauce.',
          'Serve immediately with extra Parmesan and black pepper.',
        ],
        categories: ['Dinner', 'Italian', 'Pasta'],
        prepTimeMinutes: 10,
        cookTimeMinutes: 20,
        servings: 4,
        difficulty: 'Medium',
        rating: 5,
        isFavorite: true,
        hasCooked: true,
        photoUrls: [],
        sourceUrl: 'https://example.com/carbonara',
        notes: 'No cream! The sauce should be silky from the eggs and pasta water.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),

      // Recipe 6: Banana Bread
      models.Recipe(
        id: _uuid.v4(),
        title: 'Moist Banana Bread',
        ingredients: [
          models.Ingredient(name: 'Ripe bananas (mashed)', quantity: 3, unit: 'large'),
          models.Ingredient(name: 'Butter (melted)', quantity: 0.33, unit: 'cup'),
          models.Ingredient(name: 'Sugar', quantity: 0.75, unit: 'cup'),
          models.Ingredient(name: 'Egg (beaten)', quantity: 1, unit: 'large'),
          models.Ingredient(name: 'Vanilla extract', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Baking soda', quantity: 1, unit: 'tsp'),
          models.Ingredient(name: 'Salt', quantity: 0.25, unit: 'tsp'),
          models.Ingredient(name: 'All-purpose flour', quantity: 1.5, unit: 'cups'),
          models.Ingredient(name: 'Walnuts (optional)', quantity: 0.5, unit: 'cup'),
        ],
        directions: [
          'Preheat oven to 350°F (175°C). Grease a 9x5 inch loaf pan.',
          'In a large bowl, mix melted butter and mashed bananas.',
          'Stir in sugar, beaten egg, and vanilla.',
          'Sprinkle baking soda and salt over mixture and stir.',
          'Add flour and mix until just incorporated. Don\'t overmix.',
          'Fold in walnuts if using.',
          'Pour batter into prepared loaf pan.',
          'Bake for 60-65 minutes, until a toothpick inserted in center comes out clean.',
          'Cool in pan for 10 minutes, then turn out onto wire rack.',
        ],
        categories: ['Breakfast', 'Baking', 'Dessert'],
        prepTimeMinutes: 15,
        cookTimeMinutes: 65,
        servings: 8,
        difficulty: 'Easy',
        rating: 4,
        isFavorite: false,
        hasCooked: false,
        photoUrls: [],
        notes: 'Perfect for using up overripe bananas! Freezes well.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Recipe 7: Quick Tacos
      models.Recipe(
        id: _uuid.v4(),
        title: 'Easy Beef Tacos',
        ingredients: [
          models.Ingredient(name: 'Ground beef', quantity: 1, unit: 'lb'),
          models.Ingredient(name: 'Taco seasoning', quantity: 2, unit: 'tbsp'),
          models.Ingredient(name: 'Water', quantity: 0.5, unit: 'cup'),
          models.Ingredient(name: 'Taco shells', quantity: 12, unit: 'pieces'),
          models.Ingredient(name: 'Lettuce (shredded)', quantity: 2, unit: 'cups'),
          models.Ingredient(name: 'Tomato (diced)', quantity: 1, unit: 'large'),
          models.Ingredient(name: 'Cheddar cheese (shredded)', quantity: 1, unit: 'cup'),
          models.Ingredient(name: 'Sour cream', quantity: 0.5, unit: 'cup'),
          models.Ingredient(name: 'Salsa', quantity: 1, unit: 'cup'),
        ],
        directions: [
          'Brown ground beef in a large skillet over medium-high heat, breaking it up as it cooks.',
          'Drain excess fat.',
          'Add taco seasoning and water. Simmer for 5 minutes until thickened.',
          'Warm taco shells according to package directions.',
          'Fill each shell with seasoned beef.',
          'Top with lettuce, tomatoes, cheese, sour cream, and salsa.',
          'Serve immediately with lime wedges.',
        ],
        categories: ['Dinner', 'Mexican', 'Quick & Easy'],
        prepTimeMinutes: 10,
        cookTimeMinutes: 15,
        servings: 6,
        difficulty: 'Easy',
        rating: 4,
        isFavorite: false,
        hasCooked: true,
        photoUrls: [],
        notes: 'Kids favorite! Can also use ground turkey.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Check if sample data has already been inserted
  static Future<bool> hasSampleData(RecipeRepository repository) async {
    final recipes = await repository.getAllRecipes();
    return recipes.isNotEmpty;
  }

  /// Insert sample data only if database is empty
  static Future<void> insertSampleDataIfNeeded(RecipeRepository repository) async {
    if (!await hasSampleData(repository)) {
      await insertSampleRecipes(repository);
    }
  }
}
