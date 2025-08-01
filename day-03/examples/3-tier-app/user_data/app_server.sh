#!/bin/bash
# Application Server User Data Script - Tier 2 (Application Layer)

# Update system
yum update -y

# Install required packages
yum install -y java-11-amazon-corretto python3 python3-pip mysql curl wget

# Install Node.js (for our simple app server)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Create simple Node.js application server
cat > /opt/app/server.js << 'EOF'
const express = require('express');
const mysql = require('mysql2');
const app = express();
const port = 8080;

// Database configuration
const dbConfig = {
    host: '${database_endpoint}'.split(':')[0],
    user: '${database_username}',
    password: process.env.DB_PASSWORD || 'changeme123!',
    database: '${database_name}',
    connectTimeout: 10000,
    acquireTimeout: 10000,
    timeout: 10000
};

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// Application info endpoint
app.get('/info', (req, res) => {
    const info = {
        service: 'Application Layer',
        tier: 2,
        project: '${project_name}',
        environment: '${environment}',
        timestamp: new Date().toISOString(),
        database_host: '${database_endpoint}'.split(':')[0],
        status: 'healthy'
    };
    res.json(info);
});

// Database connection test
app.get('/db-test', async (req, res) => {
    try {
        const connection = mysql.createConnection(dbConfig);
        
        connection.connect((err) => {
            if (err) {
                console.error('Database connection failed:', err);
                res.status(500).json({
                    status: 'error',
                    message: 'Database connection failed',
                    error: err.message
                });
                return;
            }
            
            connection.query('SELECT 1 as test', (error, results) => {
                connection.end();
                
                if (error) {
                    res.status(500).json({
                        status: 'error',
                        message: 'Database query failed',
                        error: error.message
                    });
                } else {
                    res.json({
                        status: 'success',
                        message: 'Database connection successful',
                        timestamp: new Date().toISOString()
                    });
                }
            });
        });
    } catch (error) {
        res.status(500).json({
            status: 'error',
            message: 'Database connection error',
            error: error.message
        });
    }
});

// Sample API endpoints
app.get('/api/users', (req, res) => {
    // Simulate user data
    const users = [
        { id: 1, name: 'John Doe', email: 'john@example.com' },
        { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
    ];
    res.json(users);
});

app.get('/api/status', (req, res) => {
    const status = {
        application: 'healthy',
        database: 'connected',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        timestamp: new Date().toISOString()
    };
    res.json(status);
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        status: 'error',
        message: 'Internal server error'
    });
});

// Start server
app.listen(port, '0.0.0.0', () => {
    console.log(`Application server running on port ${port}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Database host: ${dbConfig.host}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, shutting down gracefully');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT received, shutting down gracefully');
    process.exit(0);
});
EOF

# Create package.json
cat > /opt/app/package.json << 'EOF'
{
  "name": "3tier-app-server",
  "version": "1.0.0",
  "description": "Application layer for 3-tier architecture demo",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0"
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
EOF

# Install Node.js dependencies
cd /opt/app
npm install

# Create systemd service
cat > /etc/systemd/system/app-server.service << 'EOF'
[Unit]
Description=3-Tier Application Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=DB_PASSWORD=changeme123!

# Logging
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=app-server

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/app
chmod +x /opt/app/server.js

# Enable and start the service
systemctl daemon-reload
systemctl enable app-server
systemctl start app-server

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Create CloudWatch config
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/app-server",
                        "log_stream_name": "{instance_id}/messages"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "3TierApp/ApplicationLayer",
        "metrics_collected": {
            "cpu": {
                "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            },
            "mem": {
                "measurement": ["mem_used_percent"],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Wait for service to start
sleep 10

# Test the service
curl -f http://localhost:8080/health || echo "Service health check failed"

# Log completion
echo "$(date): Application server setup completed" >> /var/log/user-data.log
echo "Service status: $(systemctl is-active app-server)" >> /var/log/user-data.log