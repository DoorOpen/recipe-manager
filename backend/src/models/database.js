const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class Database {
  constructor(dbPath) {
    this.dbPath = dbPath || process.env.DATABASE_PATH || './cart_jobs.db';
    this.db = null;
  }

  async init() {
    return new Promise((resolve, reject) => {
      this.db = new sqlite3.Database(this.dbPath, (err) => {
        if (err) {
          console.error('Error opening database:', err);
          reject(err);
        } else {
          console.log('Database connected:', this.dbPath);
          this.createTables().then(resolve).catch(reject);
        }
      });
    });
  }

  async createTables() {
    const createCartJobsTable = `
      CREATE TABLE IF NOT EXISTS cart_jobs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        retailer TEXT NOT NULL,
        status TEXT NOT NULL,
        items TEXT NOT NULL,
        share_url TEXT,
        error_message TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        completed_at INTEGER,
        webhook_url TEXT,
        webhook_delivered INTEGER DEFAULT 0
      )
    `;

    const createJobLogsTable = `
      CREATE TABLE IF NOT EXISTS job_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_id TEXT NOT NULL,
        level TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (job_id) REFERENCES cart_jobs(id)
      )
    `;

    const createUsersTable = `
      CREATE TABLE IF NOT EXISTS users (
        user_id TEXT PRIMARY KEY,
        subscription_tier TEXT NOT NULL,
        cart_jobs_created INTEGER DEFAULT 0,
        cart_jobs_succeeded INTEGER DEFAULT 0,
        cart_jobs_failed INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    `;

    return new Promise((resolve, reject) => {
      this.db.serialize(() => {
        this.db.run(createCartJobsTable, (err) => {
          if (err) reject(err);
        });
        this.db.run(createJobLogsTable, (err) => {
          if (err) reject(err);
        });
        this.db.run(createUsersTable, (err) => {
          if (err) reject(err);
          else resolve();
        });
      });
    });
  }

  // Cart Job Methods
  async createCartJob(job) {
    const sql = `
      INSERT INTO cart_jobs (
        id, user_id, retailer, status, items, created_at, updated_at, webhook_url
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;

    return new Promise((resolve, reject) => {
      this.db.run(
        sql,
        [
          job.id,
          job.userId,
          job.retailer,
          job.status,
          JSON.stringify(job.items),
          job.createdAt,
          job.updatedAt,
          job.webhookUrl || null
        ],
        function(err) {
          if (err) reject(err);
          else resolve(job);
        }
      );
    });
  }

  async updateCartJob(jobId, updates) {
    const allowedFields = ['status', 'share_url', 'error_message', 'updated_at', 'completed_at', 'webhook_delivered'];
    const fields = Object.keys(updates).filter(key => allowedFields.includes(key));

    if (fields.length === 0) return;

    const setClause = fields.map(field => `${field} = ?`).join(', ');
    const values = fields.map(field => updates[field]);
    values.push(jobId);

    const sql = `UPDATE cart_jobs SET ${setClause} WHERE id = ?`;

    return new Promise((resolve, reject) => {
      this.db.run(sql, values, function(err) {
        if (err) reject(err);
        else resolve({ changes: this.changes });
      });
    });
  }

  async getCartJob(jobId) {
    const sql = 'SELECT * FROM cart_jobs WHERE id = ?';

    return new Promise((resolve, reject) => {
      this.db.get(sql, [jobId], (err, row) => {
        if (err) reject(err);
        else if (row) {
          row.items = JSON.parse(row.items);
          resolve(row);
        } else {
          resolve(null);
        }
      });
    });
  }

  async getUserCartJobs(userId, limit = 50) {
    const sql = `
      SELECT * FROM cart_jobs
      WHERE user_id = ?
      ORDER BY created_at DESC
      LIMIT ?
    `;

    return new Promise((resolve, reject) => {
      this.db.all(sql, [userId, limit], (err, rows) => {
        if (err) reject(err);
        else {
          rows.forEach(row => {
            row.items = JSON.parse(row.items);
          });
          resolve(rows);
        }
      });
    });
  }

  async getPendingJobs() {
    const sql = `SELECT * FROM cart_jobs WHERE status = 'pending' ORDER BY created_at ASC`;

    return new Promise((resolve, reject) => {
      this.db.all(sql, [], (err, rows) => {
        if (err) reject(err);
        else {
          rows.forEach(row => {
            row.items = JSON.parse(row.items);
          });
          resolve(rows);
        }
      });
    });
  }

  // Job Logging
  async logJobEvent(jobId, level, message) {
    const sql = `
      INSERT INTO job_logs (job_id, level, message, timestamp)
      VALUES (?, ?, ?, ?)
    `;

    return new Promise((resolve, reject) => {
      this.db.run(
        sql,
        [jobId, level, message, Date.now()],
        function(err) {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }

  async getJobLogs(jobId) {
    const sql = `SELECT * FROM job_logs WHERE job_id = ? ORDER BY timestamp ASC`;

    return new Promise((resolve, reject) => {
      this.db.all(sql, [jobId], (err, rows) => {
        if (err) reject(err);
        else resolve(rows);
      });
    });
  }

  // User Methods
  async getOrCreateUser(userId) {
    const sql = 'SELECT * FROM users WHERE user_id = ?';

    return new Promise((resolve, reject) => {
      this.db.get(sql, [userId], (err, row) => {
        if (err) {
          reject(err);
        } else if (row) {
          resolve(row);
        } else {
          // Create new user
          const now = Date.now();
          const insertSql = `
            INSERT INTO users (user_id, subscription_tier, created_at, updated_at)
            VALUES (?, ?, ?, ?)
          `;
          this.db.run(insertSql, [userId, 'free', now, now], function(err) {
            if (err) reject(err);
            else {
              resolve({
                user_id: userId,
                subscription_tier: 'free',
                cart_jobs_created: 0,
                cart_jobs_succeeded: 0,
                cart_jobs_failed: 0,
                created_at: now,
                updated_at: now
              });
            }
          });
        }
      });
    });
  }

  async incrementUserJobCount(userId, success = false) {
    const field = success ? 'cart_jobs_succeeded' : 'cart_jobs_failed';
    const sql = `
      UPDATE users
      SET cart_jobs_created = cart_jobs_created + 1,
          ${field} = ${field} + 1,
          updated_at = ?
      WHERE user_id = ?
    `;

    return new Promise((resolve, reject) => {
      this.db.run(sql, [Date.now(), userId], function(err) {
        if (err) reject(err);
        else resolve();
      });
    });
  }

  close() {
    if (this.db) {
      this.db.close((err) => {
        if (err) console.error('Error closing database:', err);
        else console.log('Database connection closed');
      });
    }
  }
}

module.exports = Database;
