require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const Database = require('./models/database');
const WalmartCartService = require('./services/WalmartCartService');
const cartRoutes = require('./routes/cart');
const recipeRoutes = require('./routes/recipes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Initialize services
async function initializeServices() {
  console.log('Initializing services...');

  // Initialize database
  const db = new Database();
  await db.init();

  // Initialize Walmart cart service
  const walmartCartService = new WalmartCartService(db, console);

  // Store in app locals for access in routes
  app.locals.db = db;
  app.locals.walmartCartService = walmartCartService;
  app.locals.jobQueue = [];
  app.locals.isProcessing = false;

  console.log('Services initialized successfully');
}

// Routes
app.get('/', (req, res) => {
  res.json({
    service: 'Recipe Manager Cart Automation Service',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      createWalmartCart: 'POST /api/cart/create-walmart',
      getJobStatus: 'GET /api/cart/job/:jobId',
      getUserJobs: 'GET /api/cart/jobs',
      cancelJob: 'DELETE /api/cart/job/:jobId',
      scanRecipe: 'POST /api/recipes/scan',
      validateRecipe: 'POST /api/recipes/scan/validate',
      ocrHealth: 'GET /api/recipes/scan/health'
    }
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: Date.now(),
    uptime: process.uptime(),
    queueLength: app.locals.jobQueue?.length || 0,
    isProcessing: app.locals.isProcessing || false
  });
});

// API routes
app.use('/api/cart', cartRoutes);
app.use('/api/recipes', recipeRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Start server
async function start() {
  try {
    await initializeServices();

    app.listen(PORT, () => {
      console.log(`\n🚀 Cart Automation Service running on port ${PORT}`);
      console.log(`📍 http://localhost:${PORT}`);
      console.log(`🏥 Health check: http://localhost:${PORT}/health`);
      console.log(`\nEnvironment: ${process.env.NODE_ENV || 'development'}\n`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully...');

  if (app.locals.db) {
    app.locals.db.close();
  }

  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('\nSIGINT received, shutting down gracefully...');

  if (app.locals.db) {
    app.locals.db.close();
  }

  process.exit(0);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Start the server
start();

module.exports = app;
