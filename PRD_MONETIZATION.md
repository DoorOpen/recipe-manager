# Recipe Manager - Monetization Features PRD Checklist

This document tracks implementation of **paid tier features** only. For core app features, see `PRD_CHECKLIST.md`.

---

## 📋 **SUBSCRIPTION INFRASTRUCTURE**

### Setup & Configuration
- [ ] **RevenueCat Integration** (cross-platform subscription management)
  - [ ] Create RevenueCat account
  - [ ] Configure iOS App Store Connect products
  - [ ] Configure Google Play Console products
  - [ ] Set up entitlements (free, starter, pro)
  - [ ] SDK integration in Flutter app
  - [ ] Test sandbox subscriptions

- [ ] **iOS StoreKit 2**
  - [ ] Create subscription groups in App Store Connect
  - [ ] Configure Free tier (no IAP)
  - [ ] Configure Starter Monthly ($4.99)
  - [ ] Configure Starter Annual ($39.99)
  - [ ] Configure Pro Monthly ($9.99)
  - [ ] Configure Pro Annual ($79.99)
  - [ ] Set up introductory offers (free trials)
  - [ ] Enable family sharing (Pro tier only)

- [ ] **Google Play Billing**
  - [ ] Set up billing library v5+
  - [ ] Create subscription products
  - [ ] Configure base plans and offers
  - [ ] Set up free trials
  - [ ] Enable Google Play Family Library (Pro tier)

- [ ] **Subscription State Management**
  - [ ] User model with subscription fields
    - [ ] subscriptionTier (free/starter/pro)
    - [ ] subscriptionStatus (active/canceled/expired/trial)
    - [ ] subscriptionStartDate
    - [ ] subscriptionEndDate
    - [ ] isTrialActive
    - [ ] deviceCount
  - [ ] Local subscription cache
  - [ ] Sync subscription status with backend
  - [ ] Handle subscription events (purchase, renewal, cancellation)

---

## 🔒 **FEATURE GATING SYSTEM**

### Core Gating Logic
- [ ] **Entitlement Checking Service**
  - [ ] canAccessFeature(feature) method
  - [ ] getCurrentTier() method
  - [ ] getFeatureLimitRemaining(feature) method
  - [ ] checkLimit(feature, current, max) method
  - [ ] showUpgradePrompt(feature, tier) method

- [ ] **Free Tier Limits**
  - [ ] Recipe count limit (50 max)
    - [ ] Counter in database
    - [ ] Warning at 40 recipes
    - [ ] Block at 50 recipes
    - [ ] Upgrade prompt
  - [ ] URL import limit (5/month)
    - [ ] Monthly counter with reset logic
    - [ ] Track import date
    - [ ] Reset on 1st of month
    - [ ] Show remaining imports
  - [ ] Meal plan horizon (2 weeks)
    - [ ] Block adding meals beyond 2 weeks
    - [ ] Warning when approaching limit
  - [ ] Advance planning (1 week max)
    - [ ] Block adding meals more than 1 week out
  - [ ] Grocery list limit (1 active)
    - [ ] Prevent creating 2nd list
    - [ ] Upgrade prompt
  - [ ] Pantry items limit (25 max)
    - [ ] Counter in database
    - [ ] Warning at 20 items
    - [ ] Block at 25 items

- [ ] **Tier-Based Feature Access**
  - [ ] Feature enum (FREE, STARTER, PRO)
  - [ ] Feature-to-tier mapping
  - [ ] Runtime checks before feature access
  - [ ] Graceful degradation for locked features

### UI Indicators
- [ ] **Lock Badges on Features**
  - [ ] 🔒 icon on locked features
  - [ ] "Starter" or "Pro" label
  - [ ] Tap to see upgrade options

- [ ] **Upgrade Prompts**
  - [ ] Non-intrusive dialog design
  - [ ] Show when limit hit
  - [ ] Show when locked feature tapped
  - [ ] Dismissible (don't show >1x per day)
  - [ ] Value-focused messaging
  - [ ] "Try Free" and "Learn More" buttons

- [ ] **Progress Indicators**
  - [ ] "45/50 recipes" counter in recipes screen
  - [ ] "3/5 imports this month" counter
  - [ ] "1/1 grocery lists" indicator
  - [ ] "23/25 pantry items" counter

---

## 🎨 **PAYWALL & SUBSCRIPTION UI**

### Paywall Screens
- [ ] **Main Paywall Screen**
  - [ ] Beautiful hero image
  - [ ] Clear tier comparison
  - [ ] Pricing cards (monthly/annual toggle)
  - [ ] Feature highlights for each tier
  - [ ] Testimonials/social proof
  - [ ] "Start Free Trial" CTA
  - [ ] "Restore Purchases" button
  - [ ] Terms and Privacy Policy links

- [ ] **Contextual Upgrade Prompts**
  - [ ] Mini paywall dialog (specific feature)
  - [ ] Before/after comparison
  - [ ] Single tier focus (show best upgrade)
  - [ ] Quick dismiss option

- [ ] **Free Trial Offer Screen**
  - [ ] Countdown timer ("Offer expires in 3 days")
  - [ ] What's included in trial
  - [ ] When payment starts
  - [ ] How to cancel
  - [ ] "Start 14-Day Free Trial" CTA

### Settings > Subscription Management
- [ ] **Current Plan Display**
  - [ ] Tier badge (Free/Starter/Pro)
  - [ ] Price and billing cycle
  - [ ] Renewal date
  - [ ] Trial status (if applicable)
  - [ ] Feature list for current tier

- [ ] **Plan Comparison**
  - [ ] Side-by-side feature table
  - [ ] Highlight differences
  - [ ] Current tier marked
  - [ ] Upgrade/Downgrade buttons

- [ ] **Manage Subscription**
  - [ ] "Upgrade to Pro" button (if on Starter)
  - [ ] "Upgrade to Starter" button (if on Free)
  - [ ] "Manage in App Store/Play Store" link
  - [ ] "Cancel Subscription" button
  - [ ] "Restore Purchases" button

- [ ] **Billing History**
  - [ ] Past payments list
  - [ ] Receipts download
  - [ ] Next billing date

### In-App Purchase Flow
- [ ] **Purchase Confirmation**
  - [ ] Loading indicator during purchase
  - [ ] Success animation
  - [ ] "Welcome to [Tier]!" screen
  - [ ] Feature tour for new tier
  - [ ] Error handling (payment failed, etc.)

- [ ] **Restore Purchases**
  - [ ] Check App Store/Play Store
  - [ ] Sync with backend
  - [ ] Update local state
  - [ ] Show success/failure message

---

## 🆓 **FREE TIER - LIMIT ENFORCEMENT**

### Recipe Limits
- [ ] **50 Recipe Hard Cap**
  - [ ] Count recipes on add
  - [ ] Block if at limit
  - [ ] Show upgrade dialog
  - [ ] "Delete recipes" option

- [ ] **URL Import Limits (5/month)**
  - [ ] Track imports in database
  - [ ] Store import timestamp
  - [ ] Monthly reset job
  - [ ] Show remaining count
  - [ ] Block at 5 imports
  - [ ] Upgrade prompt

### Meal Planning Limits
- [ ] **2-Week Horizon**
  - [ ] Calculate max date (today + 14 days)
  - [ ] Block adding beyond limit
  - [ ] Gray out unavailable dates

- [ ] **1-Week Advance Planning**
  - [ ] Block adding meals >1 week from today
  - [ ] Warning message

### Grocery List Limits
- [ ] **1 Active List Only**
  - [ ] Count active lists
  - [ ] Block "Create List" if at limit
  - [ ] Suggest archiving old list
  - [ ] Upgrade prompt

### Pantry Limits
- [ ] **25 Item Cap**
  - [ ] Count pantry items on add
  - [ ] Warning at 20 items
  - [ ] Block at 25 items
  - [ ] Upgrade prompt

### Device Limits
- [ ] **Local Only (No Cloud Sync)**
  - [ ] Disable cloud sync button
  - [ ] Show "Upgrade for cloud backup" message
  - [ ] Local SQLite only

---

## 🌟 **STARTER TIER FEATURES**

### Remove All Limits
- [ ] **Unlimited Recipes**
  - [ ] Remove 50 recipe cap
  - [ ] Allow unlimited storage

- [ ] **Unlimited URL Imports**
  - [ ] Remove monthly limit
  - [ ] Unlimited imports

- [ ] **12-Week Meal Planning**
  - [ ] Extend horizon to 84 days
  - [ ] Update UI to show 3 months

- [ ] **Unlimited Grocery Lists**
  - [ ] Allow multiple lists
  - [ ] Archive old lists
  - [ ] Rename lists

- [ ] **Unlimited Pantry Items**
  - [ ] Remove 25 item cap
  - [ ] Track thousands of items

### Cloud Sync (3 Devices)
- [ ] **Cloud Backup**
  - [ ] Auto-backup to cloud on changes
  - [ ] AWS DynamoDB or Firebase
  - [ ] Encrypted backup

- [ ] **3-Device Sync**
  - [ ] Device registration system
  - [ ] Track device UUIDs
  - [ ] Show connected devices in Settings
  - [ ] "Remove Device" option
  - [ ] Block 4th device with upgrade prompt
  - [ ] Real-time sync across devices

- [ ] **Sync Conflict Resolution**
  - [ ] Last-write-wins strategy
  - [ ] Or show user diff for important conflicts

### Advanced Meal Planning
- [ ] **Drag-and-Drop Meal Planning**
  - [ ] Draggable recipe cards
  - [ ] Drop zones on calendar
  - [ ] Visual feedback during drag
  - [ ] Move meals between dates

- [ ] **Reusable Menu Templates**
  - [ ] MenuTemplate model
    - [ ] templateId, name, description
    - [ ] List of recipeIds by day/meal
    - [ ] dateCreated
  - [ ] MenuTemplateDao (CRUD)
  - [ ] "Save as Template" button
  - [ ] "Apply Template" button
  - [ ] Template library screen
  - [ ] Edit/delete templates

- [ ] **Calendar Export**
  - [ ] Export to iCal format (.ics)
  - [ ] Google Calendar sync
  - [ ] Include meal names and times

### Smart Grocery Lists
- [ ] **Auto-Generate from Meal Plan**
  - [ ] "Generate List" button on meal plan
  - [ ] Date range picker (select week)
  - [ ] Fetch all recipes in range
  - [ ] Extract all ingredients
  - [ ] Create new grocery list
  - [ ] Confirmation screen

- [ ] **Intelligent Ingredient Merging**
  - [ ] Detect duplicate ingredients
  - [ ] Sum quantities (2 eggs + 3 eggs = 5 eggs)
  - [ ] Handle unit conversions (1 cup + 250ml)
  - [ ] Show merged items in different color

- [ ] **Pantry Integration**
  - [ ] Check pantry before adding to list
  - [ ] Exclude items in pantry
  - [ ] Or mark as "Already have" with strikethrough
  - [ ] Toggle: "Exclude pantry items" checkbox

- [ ] **Custom Aisle/Category Organization**
  - [ ] Reorder categories
  - [ ] Rename categories
  - [ ] Create custom categories
  - [ ] Persist user's custom order
  - [ ] "Reset to Default" option

### Recipe Enhancements
- [ ] **Photo Upload (5 photos per recipe)**
  - [ ] Camera integration
  - [ ] Gallery picker
  - [ ] Upload to S3
  - [ ] Image thumbnails
  - [ ] Reorder photos (drag)
  - [ ] Delete photos
  - [ ] Limit to 5 in Starter

- [ ] **Recipe Sharing**
  - [ ] Share as text (plain text format)
  - [ ] Share as PDF (formatted recipe card)
  - [ ] Generate shareable link
  - [ ] Copy to clipboard
  - [ ] Share via system share sheet

- [ ] **Print-Friendly Recipe Cards**
  - [ ] PDF generation with clean layout
  - [ ] Include photo, ingredients, directions
  - [ ] Print button

### Cooking History Tracking
- [ ] **Track When Recipes Cooked**
  - [ ] lastCookedDate field in Recipe
  - [ ] timesCooked counter
  - [ ] Update when marked as cooked
  - [ ] Display in recipe detail

- [ ] **Cooking Stats**
  - [ ] Most cooked recipes
  - [ ] Cooking frequency
  - [ ] Last cooked date display
  - [ ] "Cook Again?" prompt

---

## 🚀 **PRO TIER FEATURES**

### OCR Recipe Scanning
- [ ] **OCR Integration**
  - [ ] AWS Textract integration
  - [ ] OR Google Cloud Vision API
  - [ ] Image upload to S3
  - [ ] Text extraction
  - [ ] Parse ingredients vs directions

- [ ] **OCR Camera UI**
  - [ ] Camera permission handling
  - [ ] Live camera preview
  - [ ] Capture button
  - [ ] Crop/rotate image
  - [ ] "Scan Recipe" button in add recipe screen

- [ ] **OCR Result Review**
  - [ ] Show extracted text
  - [ ] Manual correction interface
  - [ ] Side-by-side: image and parsed text
  - [ ] "Save Recipe" button
  - [ ] Handle handwritten recipes (best effort)

- [ ] **Support Multiple Sources**
  - [ ] Recipe cards (photo)
  - [ ] Cookbook pages (photo)
  - [ ] PDFs (upload and OCR)
  - [ ] Instagram/TikTok screenshots

### Grocery Delivery Integrations
- [ ] **Instacart Integration**
  - [ ] Instacart Developer API signup
  - [ ] API keys configuration
  - [ ] OAuth flow for user connection
  - [ ] "Send to Instacart" button on grocery list
  - [ ] Map ingredients to Instacart product IDs
  - [ ] Fuzzy matching for items
  - [ ] Create cart in Instacart
  - [ ] Deep link to Instacart app
  - [ ] Handle errors (out of stock, not found)

- [ ] **Walmart Grocery Integration**
  - [ ] Walmart API setup
  - [ ] Similar flow to Instacart
  - [ ] "Send to Walmart" button

- [ ] **Service Selection**
  - [ ] Settings: default grocery service
  - [ ] Multiple service connections
  - [ ] Price comparison (if APIs support)

### Auto Nutrition Tracking
- [ ] **Nutrition API Integration**
  - [ ] Edamam API signup
  - [ ] OR USDA FoodData Central
  - [ ] API key configuration

- [ ] **Auto-Calculate Nutrition**
  - [ ] Parse ingredients
  - [ ] Fetch nutrition data for each ingredient
  - [ ] Sum totals (calories, protein, carbs, fat, etc.)
  - [ ] Calculate per serving
  - [ ] Cache results (avoid repeated API calls)
  - [ ] "Calculate Nutrition" button

- [ ] **Nutrition Display**
  - [ ] Nutrition facts label design
  - [ ] Macros pie chart
  - [ ] Daily value percentages
  - [ ] Per serving display
  - [ ] Scale with serving adjustments

- [ ] **Meal Plan Nutrition Summary**
  - [ ] Weekly nutrition overview
  - [ ] Daily calorie totals
  - [ ] Macros breakdown by day
  - [ ] Progress toward goals

- [ ] **Dietary Analysis**
  - [ ] Auto-detect: vegetarian, vegan, gluten-free
  - [ ] Allergen warnings (nuts, dairy, etc.)
  - [ ] Ingredient scanning for dietary flags

### Voice Assistant Integration
- [ ] **Siri Shortcuts (iOS)**
  - [ ] SiriKit intents definition
  - [ ] "Add to grocery list" intent
  - [ ] "What's for dinner?" intent
  - [ ] "Start cooking [recipe]" intent
  - [ ] Donate shortcuts on actions
  - [ ] Custom phrases setup

- [ ] **Google Assistant (Android)**
  - [ ] Actions on Google setup
  - [ ] Similar intents as Siri
  - [ ] Voice command handling

- [ ] **Alexa Skill (Optional)**
  - [ ] Alexa skill development
  - [ ] Account linking
  - [ ] Voice commands

### Family Sharing (5 Members)
- [ ] **Household Account System**
  - [ ] Household model
    - [ ] householdId, ownerUserId, name
    - [ ] memberUserIds (array, max 5)
    - [ ] createdDate
  - [ ] HouseholdDao (CRUD)

- [ ] **Invite Family Members**
  - [ ] Email invitation system
  - [ ] Invitation codes
  - [ ] Accept/decline invitations
  - [ ] "Add Family Member" UI
  - [ ] Show pending invitations

- [ ] **Shared Data**
  - [ ] Shared recipe collection
  - [ ] Shared grocery lists
  - [ ] Shared meal plans
  - [ ] Shared pantry
  - [ ] Real-time sync across members

- [ ] **Permissions System**
  - [ ] Role enum: Owner, Admin, Member, Viewer
  - [ ] Owner: full control
  - [ ] Admin: edit all, can't delete household
  - [ ] Member: edit own content, view all
  - [ ] Viewer: read-only
  - [ ] Set permissions per user

- [ ] **Activity Feed**
  - [ ] "Sarah added 'Chicken Parmesan'"
  - [ ] "Mike checked off 'milk' on grocery list"
  - [ ] "Emma planned dinner for Thursday"
  - [ ] ActivityLog model and display

### Advanced Pantry Features
- [ ] **Barcode Scanning**
  - [ ] Camera barcode detection
  - [ ] UPC/EAN barcode formats
  - [ ] UPC database API (Open Food Facts, etc.)
  - [ ] Fetch product details (name, brand, size)
  - [ ] Auto-populate pantry item form
  - [ ] Manual override option
  - [ ] "Scan Barcode" button

- [ ] **Auto-Decrement Pantry After Cooking**
  - [ ] "Update Pantry?" prompt after cooking
  - [ ] Show ingredients used in recipe
  - [ ] Calculate quantities used (based on servings cooked)
  - [ ] Deduct from pantry inventory
  - [ ] One-tap update
  - [ ] Manual adjustment option

- [ ] **Freezer Meal Tracking**
  - [ ] FreezerMeal model
    - [ ] freezerMealId, recipeId, recipeName
    - [ ] portionCount, portionSize
    - [ ] dateFrozen, containerInfo
  - [ ] FreezerMealDao
  - [ ] "Log Freezer Meal" after cooking
  - [ ] Freezer inventory screen
  - [ ] "Use Portion" button (decrements count)
  - [ ] Add to meal plan from freezer inventory

- [ ] **Smart Restocking**
  - [ ] Track usage patterns
  - [ ] Low stock threshold per item
  - [ ] Auto-add to grocery list when low
  - [ ] "Restock Suggestions" screen
  - [ ] Recurring item detection

### Enhanced Recipe Features
- [ ] **Unlimited Photos**
  - [ ] Remove 5-photo limit
  - [ ] Allow up to 20 photos
  - [ ] Photo gallery view

- [ ] **Video Support**
  - [ ] Video upload to S3
  - [ ] Embedded video player
  - [ ] YouTube link embedding
  - [ ] Play in recipe detail screen

- [ ] **Multi-Recipe Cooking Mode**
  - [ ] "Pin Recipe" feature
  - [ ] Show multiple recipes at once
  - [ ] Quick toggle between pinned recipes
  - [ ] Tabs or swipeable cards
  - [ ] Unpin recipe option

- [ ] **Smart Timers**
  - [ ] Auto-detect timer text in recipe
    - [ ] Regex: "bake for 20 minutes", "cook 30 min", etc.
  - [ ] Suggest timers during cooking mode
  - [ ] Multiple simultaneous timers
  - [ ] Named timers ("Bake cake", "Boil pasta")
  - [ ] Notifications when timer ends
  - [ ] Sound/vibration
  - [ ] Snooze option
  - [ ] Timer widget overlay

### AI-Powered Features
- [ ] **AI Meal Planning**
  - [ ] "Plan My Week" button
  - [ ] User preferences input:
    - [ ] Dietary restrictions
    - [ ] Cook time limits (e.g., <30 min on weeknights)
    - [ ] Variety preferences (no repeats)
  - [ ] Generate balanced meal plan
  - [ ] AI service: OpenAI API or custom model
  - [ ] Show suggested plan
  - [ ] Accept/regenerate/edit options

- [ ] **Recipe Recommendations**
  - [ ] "What Should I Cook?" feature
  - [ ] Based on pantry contents
  - [ ] Based on cooking history
  - [ ] Based on season/weather
  - [ ] Personalized suggestions
  - [ ] ML model (simple collaborative filtering)

### Bulk Import/Export
- [ ] **Bulk Import**
  - [ ] Import from Paprika (JSON export)
  - [ ] Import from other apps (standard formats)
  - [ ] CSV import
  - [ ] Batch URL import (paste multiple URLs)
  - [ ] Progress indicator
  - [ ] Error handling (skip failed imports)

- [ ] **Advanced Export**
  - [ ] Export all recipes as PDF cookbook
  - [ ] Custom formatting options
  - [ ] Include/exclude photos
  - [ ] Table of contents
  - [ ] Professional layout
  - [ ] Share or print

### Recipe Analytics
- [ ] **Usage Statistics**
  - [ ] Most popular recipes (by cook count)
  - [ ] Cooking streaks (days in a row)
  - [ ] Total recipes cooked this month/year
  - [ ] Average cook time per week

- [ ] **Cost Analysis**
  - [ ] Estimate cost per serving
  - [ ] Ingredient price database (optional)
  - [ ] Track grocery spending
  - [ ] Budget tracking

- [ ] **Analytics Dashboard**
  - [ ] Charts and graphs
  - [ ] Cooking trends over time
  - [ ] Most-used ingredients
  - [ ] Category breakdown

### Unlimited Device Sync
- [ ] **10-Device Limit**
  - [ ] Track up to 10 devices
  - [ ] Device management UI
  - [ ] Remove old devices
  - [ ] Real-time sync across all

---

## 🎁 **PROMOTIONAL FEATURES**

### Free Trials
- [ ] **Starter Free Trial (14 days)**
  - [ ] No credit card required
  - [ ] Full Starter access
  - [ ] Trial countdown in UI
  - [ ] Expiration reminder (3 days before)
  - [ ] Easy upgrade to paid

- [ ] **Pro Free Trial (7 days)**
  - [ ] Credit card required
  - [ ] Full Pro access
  - [ ] Trial countdown
  - [ ] Reminder to cancel if needed

### Launch Promotions
- [ ] **Founding Member Discount**
  - [ ] First 1,000 users: lifetime 30% off
  - [ ] Special badge: "Founding Member"
  - [ ] Promo code redemption

- [ ] **Annual Launch Special**
  - [ ] Pro Annual: $49.99 (normally $79.99)
  - [ ] Limited time offer
  - [ ] Countdown timer

### Referral Program
- [ ] **Referral System**
  - [ ] Generate referral code
  - [ ] Share link (social, email)
  - [ ] Track referrals
  - [ ] Reward: 1 month free per referral
  - [ ] Referral dashboard
  - [ ] "Invite Friends" screen

- [ ] **Referral Credits**
  - [ ] Apply free months to subscription
  - [ ] Show credit balance
  - [ ] Auto-apply at renewal

---

## 📊 **ANALYTICS & TRACKING**

### Subscription Metrics
- [ ] **Track Key Events**
  - [ ] Free trial starts
  - [ ] Trial conversions
  - [ ] Paid subscription purchases
  - [ ] Subscription renewals
  - [ ] Cancellations
  - [ ] Downgrades/upgrades

- [ ] **Revenue Tracking**
  - [ ] MRR (Monthly Recurring Revenue)
  - [ ] ARR (Annual Recurring Revenue)
  - [ ] ARPU (Average Revenue Per User)
  - [ ] Churn rate
  - [ ] LTV (Lifetime Value)

- [ ] **Feature Usage by Tier**
  - [ ] Track which features drive retention
  - [ ] Most-used Pro features
  - [ ] Identify upgrade triggers

### A/B Testing
- [ ] **Paywall Variations**
  - [ ] Test different designs
  - [ ] Test pricing displays
  - [ ] Test messaging
  - [ ] Track conversion rates

- [ ] **Upgrade Prompt Variations**
  - [ ] Test timing (when to show)
  - [ ] Test messaging
  - [ ] Test incentives

### Churn Prevention
- [ ] **Cancellation Flow**
  - [ ] Exit survey ("Why are you leaving?")
  - [ ] Offer discount to stay
  - [ ] Offer downgrade instead of cancel
  - [ ] Track cancellation reasons

- [ ] **Win-Back Campaigns**
  - [ ] Email lapsed subscribers
  - [ ] Special re-activation offer
  - [ ] Highlight new features

---

## 🧪 **TESTING**

### Subscription Testing
- [ ] **Sandbox Testing**
  - [ ] iOS sandbox accounts
  - [ ] Google Play test accounts
  - [ ] Test purchase flow
  - [ ] Test renewals
  - [ ] Test cancellations
  - [ ] Test family sharing

- [ ] **Edge Cases**
  - [ ] Payment failure
  - [ ] Subscription expired
  - [ ] Downgrade with excess data
  - [ ] Upgrade mid-cycle
  - [ ] Restore purchases on new device
  - [ ] Multiple devices syncing

### Feature Gating Tests
- [ ] **Verify Limits Work**
  - [ ] Free tier can't exceed 50 recipes
  - [ ] Free tier can't create 2nd grocery list
  - [ ] Starter tier can sync 3 devices (not 4)
  - [ ] Pro tier can add 5 family members (not 6)

- [ ] **Graceful Degradation**
  - [ ] Downgrade from Starter to Free with 100 recipes
  - [ ] Keep all data, but read-only for excess
  - [ ] Clear messaging about what happens

---

## 🚀 **ROLLOUT PLAN**

### Phase 1: Infrastructure (Month 1-2)
- [ ] Set up RevenueCat
- [ ] Configure App Store/Play Store products
- [ ] Implement subscription state management
- [ ] Build paywall UI
- [ ] Implement feature gating
- [ ] Test in sandbox

### Phase 2: Free Tier Limits (Month 3)
- [ ] Implement all Free tier limits
- [ ] Add upgrade prompts
- [ ] Test limit enforcement
- [ ] Launch Free tier to public

### Phase 3: Starter Launch (Month 4)
- [ ] Build Starter features (cloud sync, templates, auto-generate lists)
- [ ] Launch with 14-day free trial
- [ ] Founding member promotion
- [ ] Monitor conversions

### Phase 4: Pro Features (Month 6-9)
- [ ] Phase 4a: OCR scanning
- [ ] Phase 4b: Instacart integration
- [ ] Phase 4c: Nutrition tracking
- [ ] Phase 4d: Family sharing
- [ ] Launch Pro tier
- [ ] 7-day Pro trial for Starter users

### Phase 5: Optimization (Month 10-12)
- [ ] A/B test pricing
- [ ] Refine feature placement
- [ ] Add requested features
- [ ] Optimize conversion funnels

---

## ✅ **SUCCESS CRITERIA**

### Year 1 Goals
- [ ] 20,000 total users
- [ ] 5% free-to-paid conversion
- [ ] 1,000 paid subscribers
- [ ] $5,400 MRR
- [ ] <5% monthly churn
- [ ] 40% trial-to-paid conversion

### Key Metrics Dashboard
- [ ] Build admin dashboard
- [ ] Real-time MRR tracking
- [ ] Conversion funnel visualization
- [ ] Churn rate monitoring
- [ ] Feature usage heatmap
- [ ] Revenue forecasting

---

## 📝 **DOCUMENTATION**

- [ ] Developer documentation for subscription system
- [ ] Feature gating guide for new features
- [ ] Testing guide for subscriptions
- [ ] User-facing tier comparison page
- [ ] FAQ for subscriptions
- [ ] Privacy policy updates (payment processing)
- [ ] Terms of service updates (subscription terms)

---

**This PRD covers all monetization features. Track progress here separately from core app features.**

**Total Estimated Work:** 6-9 months for full implementation (Phases 1-5)
