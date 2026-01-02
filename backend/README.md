# Recipe Manager - Cart Automation Backend

Backend service for automated grocery cart creation using web scraping with Puppeteer.

## Features

- 🛒 **Automated Cart Creation**: Scrapes Walmart.com and automatically adds items to cart
- 🔄 **Job Queue System**: Asynchronous job processing with status tracking
- 📊 **Job Logging**: Detailed logs for each cart creation attempt
- 🔔 **Webhook Notifications**: Send cart URLs back to app via webhooks
- 💎 **Premium Feature Gating**: Restrict access to premium subscribers
- 🔒 **User Authentication**: Token-based authentication
- 📈 **Usage Analytics**: Track success/failure rates per user

## Architecture

```
User App → POST /create-walmart-cart → Backend
                                          ↓
                                    Job Queue
                                          ↓
                                    Puppeteer
                                          ↓
                                    Walmart.com
                                          ↓
                                    Cart Created
                                          ↓
                              Webhook → User App
```

## Prerequisites

- Node.js 18+ and npm
- Chrome/Chromium (installed automatically with Puppeteer)
- SQLite3

## Installation

1. Install dependencies:
```bash
cd backend
npm install
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your settings
```

3. Start the server:
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Create Walmart Cart
```http
POST /api/cart/create-walmart
Authorization: Bearer <user-token>
Content-Type: application/json

{
  "items": [
    { "name": "Tomatoes", "quantity": 2 },
    { "name": "Garlic", "quantity": 1 }
  ],
  "webhookUrl": "https://your-app.com/webhook/cart-completed"
}

Response:
{
  "jobId": "uuid",
  "status": "pending",
  "estimatedTime": 30,
  "createdAt": 1234567890
}
```

### Get Job Status
```http
GET /api/cart/job/:jobId
Authorization: Bearer <user-token>

Response:
{
  "jobId": "uuid",
  "status": "completed",
  "shareUrl": "https://walmart.com/cart/shared/ABC123",
  "itemCount": 10,
  "logs": [...]
}
```

### Get User's Jobs
```http
GET /api/cart/jobs?limit=50
Authorization: Bearer <user-token>

Response:
{
  "jobs": [...],
  "total": 25
}
```

### Cancel Job
```http
DELETE /api/cart/job/:jobId
Authorization: Bearer <user-token>
```

## Database Schema

### cart_jobs
- `id` - Job UUID
- `user_id` - User who created the job
- `retailer` - Retailer name (walmart, instacart, etc.)
- `status` - pending, processing, completed, failed, cancelled
- `items` - JSON array of items
- `share_url` - Shareable cart URL (when completed)
- `error_message` - Error details (when failed)
- `webhook_url` - URL to send completion webhook
- `webhook_delivered` - Boolean flag
- `created_at`, `updated_at`, `completed_at` - Timestamps

### job_logs
- `id` - Auto-increment ID
- `job_id` - Foreign key to cart_jobs
- `level` - info, warning, error
- `message` - Log message
- `timestamp` - When log was created

### users
- `user_id` - Unique user identifier
- `subscription_tier` - free, starter, pro
- `cart_jobs_created` - Total jobs created
- `cart_jobs_succeeded` - Successful jobs
- `cart_jobs_failed` - Failed jobs

## Job Statuses

- **pending**: Job queued, waiting to be processed
- **processing**: Puppeteer is currently creating the cart
- **completed**: Cart created successfully, share URL available
- **failed**: Cart creation failed, error message available
- **cancelled**: User cancelled the job

## Webhook Payload

When a cart is completed, the webhook receives:

```json
{
  "event": "cart_completed",
  "jobId": "uuid",
  "userId": "user-123",
  "shareUrl": "https://walmart.com/cart/shared/ABC123",
  "itemsAdded": 8,
  "timestamp": 1234567890
}
```

Headers:
- `Content-Type: application/json`
- `X-Webhook-Secret: <your-secret>`

## Premium Feature Gating

The service checks the user's `subscription_tier` before processing jobs:

- **free**: Blocked with 403 error
- **starter**: Allowed (with monthly limits)
- **pro**: Allowed (unlimited)

Update user tier in database:
```sql
UPDATE users SET subscription_tier = 'pro' WHERE user_id = 'user-123';
```

## Proxy Configuration (Optional)

To avoid IP blocking, configure residential proxies:

```env
PROXY_HOST=proxy.example.com
PROXY_PORT=8080
PROXY_USERNAME=user
PROXY_PASSWORD=pass
```

Recommended proxy providers:
- BrightData (residential proxies)
- Oxylabs
- SmartProxy

## How It Works

1. User sends cart creation request with list of items
2. Backend creates job in database with status "pending"
3. Job is added to processing queue
4. Puppeteer launches headless browser
5. For each item:
   - Search for item on Walmart.com
   - Click first result's "Add to Cart" button
   - Adjust quantity if needed
   - Random delay (2-5 seconds) to appear human-like
6. Navigate to cart page
7. Get shareable cart URL (or use direct cart link)
8. Update job status to "completed"
9. Send webhook notification to app
10. App receives webhook and opens cart in user's browser

## Security Considerations

⚠️ **Legal Warning**: Web scraping may violate retailer Terms of Service. Use at your own risk.

**Mitigation Strategies**:
- Use residential proxies with rotation
- Add random delays between actions
- Use puppeteer-extra-plugin-stealth to avoid detection
- Limit concurrent jobs
- Monitor for blocking and implement backoff

## Deployment

### Docker (Recommended)

```dockerfile
FROM node:18-alpine

# Install Chrome dependencies
RUN apk add --no-cache chromium

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000
CMD ["node", "src/server.js"]
```

Build and run:
```bash
docker build -t cart-service .
docker run -p 3000:3000 --env-file .env cart-service
```

### Cloud Deployment

**DigitalOcean App Platform**:
- Cost: ~$12/month (Basic plan)
- Easy deployment from GitHub
- Managed database option

**AWS ECS**:
- More control over scaling
- Higher cost (~$20-50/month)

**Heroku**:
- Quick deployment
- Free tier available (with limitations)

## Monitoring

Check service health:
```bash
curl http://localhost:3000/health

{
  "status": "healthy",
  "uptime": 3600,
  "queueLength": 2,
  "isProcessing": true
}
```

## Cost Analysis

Per cart creation:
- Server CPU: ~10-30 seconds @ $0.001/min ≈ $0.0003
- Proxy (if used): ~$0.03
- **Total: ~$0.03 per cart**

Monthly costs (500 carts):
- Server: ~$12 (DigitalOcean)
- Proxies: ~$15 (500 carts × $0.03)
- **Total: ~$27/month**

Revenue (50 users @ $9.99/month):
- Revenue: $499.50
- Costs: -$27
- **Profit: $472.50/month**

## Troubleshooting

**Puppeteer fails to launch**:
```bash
# Install Chrome manually
npm install puppeteer
```

**Items not being added**:
- Check logs in database: `SELECT * FROM job_logs WHERE job_id = ?`
- Walmart may have changed selectors - update WalmartCartService.js

**Proxy not working**:
- Verify proxy credentials
- Test proxy with curl: `curl -x proxy:port https://walmart.com`

## Development

Run tests:
```bash
npm test
```

Run with auto-reload:
```bash
npm run dev
```

## License

MIT License - See LICENSE file

## Support

For issues or questions, contact support or file an issue on GitHub.
