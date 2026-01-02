const express = require('express');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();

// Middleware to verify user authentication
// In production, replace this with your actual auth system
function authenticateUser(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Extract user ID from token (simplified - use JWT in production)
  const token = authHeader.substring(7);

  // For now, we'll just use the token as user ID
  // In production, verify JWT and extract user ID
  req.userId = token;

  next();
}

// Check user subscription tier
async function checkSubscriptionTier(req, res, next) {
  try {
    const user = await req.app.locals.db.getOrCreateUser(req.userId);

    req.user = user;

    // Check if user has premium subscription
    if (user.subscription_tier === 'free') {
      return res.status(403).json({
        error: 'Premium subscription required',
        message: 'Automated cart creation is a premium feature. Please upgrade to access this feature.',
        upgradeUrl: 'https://your-app.com/upgrade'
      });
    }

    next();
  } catch (error) {
    console.error('Error checking subscription:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

// POST /api/cart/create-walmart
// Create a new Walmart cart automation job
router.post('/create-walmart', authenticateUser, checkSubscriptionTier, async (req, res) => {
  try {
    const { items, webhookUrl } = req.body;

    // Validate items
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Items array is required' });
    }

    if (items.length > 50) {
      return res.status(400).json({ error: 'Maximum 50 items allowed per cart' });
    }

    // Validate item format
    for (const item of items) {
      if (!item.name || typeof item.name !== 'string') {
        return res.status(400).json({ error: 'Each item must have a name' });
      }
    }

    // Create job
    const jobId = uuidv4();
    const now = Date.now();

    const job = {
      id: jobId,
      userId: req.userId,
      retailer: 'walmart',
      status: 'pending',
      items,
      createdAt: now,
      updatedAt: now,
      webhookUrl
    };

    await req.app.locals.db.createCartJob(job);

    // Add job to queue for processing
    req.app.locals.jobQueue.push(job);

    // Start processing if not already running
    if (!req.app.locals.isProcessing) {
      processNextJob(req.app.locals);
    }

    res.status(201).json({
      jobId,
      status: 'pending',
      message: 'Cart creation job queued',
      estimatedTime: items.length * 3, // Rough estimate: 3 seconds per item
      createdAt: now
    });

  } catch (error) {
    console.error('Error creating cart job:', error);
    res.status(500).json({ error: 'Failed to create cart job' });
  }
});

// GET /api/cart/job/:jobId
// Get status of a cart creation job
router.get('/job/:jobId', authenticateUser, async (req, res) => {
  try {
    const { jobId } = req.params;

    const job = await req.app.locals.db.getCartJob(jobId);

    if (!job) {
      return res.status(404).json({ error: 'Job not found' });
    }

    // Verify job belongs to user
    if (job.user_id !== req.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    // Get job logs
    const logs = await req.app.locals.db.getJobLogs(jobId);

    res.json({
      jobId: job.id,
      status: job.status,
      retailer: job.retailer,
      itemCount: job.items.length,
      shareUrl: job.share_url,
      errorMessage: job.error_message,
      createdAt: job.created_at,
      updatedAt: job.updated_at,
      completedAt: job.completed_at,
      logs: logs.map(log => ({
        level: log.level,
        message: log.message,
        timestamp: log.timestamp
      }))
    });

  } catch (error) {
    console.error('Error fetching job:', error);
    res.status(500).json({ error: 'Failed to fetch job status' });
  }
});

// GET /api/cart/jobs
// Get all cart jobs for current user
router.get('/jobs', authenticateUser, async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 50;

    const jobs = await req.app.locals.db.getUserCartJobs(req.userId, limit);

    res.json({
      jobs: jobs.map(job => ({
        jobId: job.id,
        status: job.status,
        retailer: job.retailer,
        itemCount: job.items.length,
        shareUrl: job.share_url,
        errorMessage: job.error_message,
        createdAt: job.created_at,
        completedAt: job.completed_at
      })),
      total: jobs.length
    });

  } catch (error) {
    console.error('Error fetching jobs:', error);
    res.status(500).json({ error: 'Failed to fetch jobs' });
  }
});

// DELETE /api/cart/job/:jobId
// Cancel a pending job
router.delete('/job/:jobId', authenticateUser, async (req, res) => {
  try {
    const { jobId } = req.params;

    const job = await req.app.locals.db.getCartJob(jobId);

    if (!job) {
      return res.status(404).json({ error: 'Job not found' });
    }

    // Verify job belongs to user
    if (job.user_id !== req.userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    // Can only cancel pending jobs
    if (job.status !== 'pending') {
      return res.status(400).json({ error: 'Can only cancel pending jobs' });
    }

    // Update status to cancelled
    await req.app.locals.db.updateCartJob(jobId, {
      status: 'cancelled',
      updated_at: Date.now(),
      completed_at: Date.now()
    });

    // Remove from queue
    req.app.locals.jobQueue = req.app.locals.jobQueue.filter(j => j.id !== jobId);

    res.json({ message: 'Job cancelled successfully' });

  } catch (error) {
    console.error('Error cancelling job:', error);
    res.status(500).json({ error: 'Failed to cancel job' });
  }
});

// Job processing function
async function processNextJob(appLocals) {
  if (appLocals.isProcessing) return;

  const { jobQueue, db, walmartCartService } = appLocals;

  if (jobQueue.length === 0) {
    appLocals.isProcessing = false;
    return;
  }

  appLocals.isProcessing = true;

  const job = jobQueue.shift();

  console.log(`Processing job ${job.id} for user ${job.userId}`);

  try {
    // Process the job based on retailer
    if (job.retailer === 'walmart') {
      await walmartCartService.createCart(job.id, job.items, job.userId);
    }
  } catch (error) {
    console.error(`Error processing job ${job.id}:`, error);
  }

  // Process next job
  appLocals.isProcessing = false;
  if (jobQueue.length > 0) {
    // Small delay before processing next job
    setTimeout(() => processNextJob(appLocals), 1000);
  }
}

module.exports = router;
