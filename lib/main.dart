import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared/theme/app_theme.dart';
import 'shared/constants/app_constants.dart';
import 'core/services/database/database.dart';
import 'core/repositories/recipe_repository.dart';
import 'core/repositories/meal_plan_repository.dart';
import 'core/repositories/grocery_repository.dart';
import 'core/repositories/pantry_repository.dart';
import 'core/utils/sample_data.dart';
import 'features/recipes/presentation/screens/recipes_screen.dart';
import 'features/meal_plan/presentation/screens/meal_plan_screen_new.dart';
import 'features/grocery_list/presentation/screens/grocery_lists_screen.dart';
import 'features/pantry/presentation/screens/pantry_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final database = AppDatabase();

  // Initialize recipe repository
  final recipeRepository = RecipeRepository(database);

  // Insert sample data if database is empty
  await SampleData.insertSampleDataIfNeeded(recipeRepository);

  runApp(RecipeManagerApp(database: database));
}

class RecipeManagerApp extends StatelessWidget {
  final AppDatabase database;

  const RecipeManagerApp({
    super.key,
    required this.database,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database
        Provider<AppDatabase>.value(value: database),

        // Repositories
        ProxyProvider<AppDatabase, RecipeRepository>(
          update: (_, db, __) => RecipeRepository(db),
        ),
        ProxyProvider<AppDatabase, MealPlanRepository>(
          update: (_, db, __) => MealPlanRepository(db),
        ),
        ProxyProvider<AppDatabase, GroceryRepository>(
          update: (_, db, __) => GroceryRepository(db),
        ),
        ProxyProvider<AppDatabase, PantryRepository>(
          update: (_, db, __) => PantryRepository(db),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: const MainNavigationScreen(),
      ),
    );
  }
}

/// Main navigation screen with bottom navigation bar
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Define all screens
  final List<Widget> _screens = const [
    RecipesScreen(),
    MealPlanScreenNew(),
    GroceryListsScreen(),
    PantryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA), // Minimal light gray background
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu),
                label: 'Recipes',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Meal Plan',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: 'Shopping',
              ),
              NavigationDestination(
                icon: Icon(Icons.kitchen_outlined),
                selectedIcon: Icon(Icons.kitchen),
                label: 'Pantry',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
