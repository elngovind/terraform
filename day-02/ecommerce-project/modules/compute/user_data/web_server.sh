#!/bin/bash
yum update -y
yum install -y httpd php php-mysqlnd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a dynamic web application
cat <<'EOF' > /var/www/html/index.php
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Commerce Platform - ${project_name}</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Arial', sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 40px;
            max-width: 800px;
            width: 90%;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #333;
            font-size: 2.5rem;
            margin-bottom: 10px;
        }
        .header p {
            color: #666;
            font-size: 1.1rem;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .info-card h3 {
            color: #333;
            margin-bottom: 10px;
        }
        .info-card p {
            color: #666;
            font-family: monospace;
        }
        .status {
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            background: #d4edda;
            border-radius: 10px;
            border: 1px solid #c3e6cb;
        }
        .status h2 {
            color: #155724;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛒 E-Commerce Platform</h1>
            <p>Environment: <strong>${environment}</strong></p>
        </div>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>🖥️ Server Info</h3>
                <p><strong>Instance ID:</strong><br><?php echo file_get_contents('http://169.254.169.254/latest/meta-data/instance-id'); ?></p>
            </div>
            <div class="info-card">
                <h3>🌍 Location</h3>
                <p><strong>Availability Zone:</strong><br><?php echo file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone'); ?></p>
            </div>
            <div class="info-card">
                <h3>⚡ Instance Type</h3>
                <p><strong>Type:</strong><br><?php echo file_get_contents('http://169.254.169.254/latest/meta-data/instance-type'); ?></p>
            </div>
            <div class="info-card">
                <h3>🕒 Timestamp</h3>
                <p><strong>Current Time:</strong><br><?php echo date('Y-m-d H:i:s T'); ?></p>
            </div>
        </div>
        
        <div class="status">
            <h2>✅ Web Tier Active</h2>
            <p>This is the web tier of our multi-tier e-commerce architecture</p>
        </div>
    </div>
</body>
</html>
EOF

# Set proper permissions
chown apache:apache /var/www/html/index.php
chmod 644 /var/www/html/index.php

# Restart Apache to load PHP
systemctl restart httpd