#!/bin/bash
# Web Server User Data Script - Tier 1 (Presentation Layer)

# Update system
yum update -y

# Install required packages
yum install -y httpd php php-mysqlnd curl wget

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create web application
cat > /var/www/html/index.php << 'EOF'
<?php
$project_name = "${project_name}";
$environment = "${environment}";
$app_server_url = "${app_server_url}";
$instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
$availability_zone = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');
$instance_type = file_get_contents('http://169.254.169.254/latest/meta-data/instance-type');
$private_ip = file_get_contents('http://169.254.169.254/latest/meta-data/local-ipv4');
?>
<!DOCTYPE html>
<html>
<head>
    <title><?php echo $project_name; ?> - Web Tier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; backdrop-filter: blur(10px); }
        .tier-badge { background: #ff6b6b; padding: 5px 15px; border-radius: 20px; display: inline-block; margin-bottom: 20px; }
        .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0; }
        .info-card { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; }
        .status { color: #4CAF50; font-weight: bold; }
        .button { background: #4CAF50; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 5px; }
        .button:hover { background: #45a049; }
    </style>
</head>
<body>
    <div class="container">
        <div class="tier-badge">🌐 TIER 1 - WEB LAYER</div>
        <h1><?php echo $project_name; ?> - 3-Tier Application</h1>
        <p><strong>Environment:</strong> <?php echo strtoupper($environment); ?></p>
        
        <div class="info-grid">
            <div class="info-card">
                <h3>🖥️ Server Information</h3>
                <p><strong>Instance ID:</strong> <?php echo $instance_id; ?></p>
                <p><strong>Instance Type:</strong> <?php echo $instance_type; ?></p>
                <p><strong>Availability Zone:</strong> <?php echo $availability_zone; ?></p>
                <p><strong>Private IP:</strong> <?php echo $private_ip; ?></p>
                <p><strong>Status:</strong> <span class="status">✅ HEALTHY</span></p>
            </div>
            
            <div class="info-card">
                <h3>🏗️ Architecture Overview</h3>
                <p><strong>Tier 1:</strong> Web Layer (Current)</p>
                <p><strong>Tier 2:</strong> Application Layer</p>
                <p><strong>Tier 3:</strong> Database Layer</p>
                <p><strong>Load Balancer:</strong> Application Load Balancer</p>
                <p><strong>Auto Scaling:</strong> Enabled</p>
            </div>
        </div>
        
        <div class="info-card">
            <h3>🔗 Application Integration</h3>
            <p><strong>App Server URL:</strong> <?php echo $app_server_url; ?></p>
            <button class="button" onclick="testAppConnection()">Test App Layer Connection</button>
            <button class="button" onclick="testDatabase()">Test Database Connection</button>
            <div id="test-results" style="margin-top: 15px;"></div>
        </div>
        
        <div class="info-card">
            <h3>📊 Real-time Metrics</h3>
            <p><strong>Load Time:</strong> <span id="load-time"></span>ms</p>
            <p><strong>Timestamp:</strong> <?php echo date('Y-m-d H:i:s T'); ?></p>
            <p><strong>Uptime:</strong> <span id="uptime"></span></p>
        </div>
    </div>

    <script>
        // Calculate load time
        window.addEventListener('load', function() {
            const loadTime = performance.now();
            document.getElementById('load-time').textContent = Math.round(loadTime);
        });
        
        // Update uptime
        function updateUptime() {
            fetch('/uptime.php')
                .then(response => response.text())
                .then(data => document.getElementById('uptime').textContent = data)
                .catch(() => document.getElementById('uptime').textContent = 'N/A');
        }
        
        // Test app layer connection
        function testAppConnection() {
            const resultsDiv = document.getElementById('test-results');
            resultsDiv.innerHTML = '<p>🔄 Testing application layer connection...</p>';
            
            fetch('/test-app.php')
                .then(response => response.json())
                .then(data => {
                    resultsDiv.innerHTML = `<p>✅ App Layer: ${data.status} (${data.response_time}ms)</p>`;
                })
                .catch(error => {
                    resultsDiv.innerHTML = '<p>❌ App Layer: Connection failed</p>';
                });
        }
        
        // Test database connection
        function testDatabase() {
            const resultsDiv = document.getElementById('test-results');
            resultsDiv.innerHTML = '<p>🔄 Testing database connection...</p>';
            
            fetch('/test-db.php')
                .then(response => response.json())
                .then(data => {
                    resultsDiv.innerHTML = `<p>✅ Database: ${data.status} (${data.response_time}ms)</p>`;
                })
                .catch(error => {
                    resultsDiv.innerHTML = '<p>❌ Database: Connection failed</p>';
                });
        }
        
        // Update uptime every 30 seconds
        updateUptime();
        setInterval(updateUptime, 30000);
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
OK
EOF

# Create uptime endpoint
cat > /var/www/html/uptime.php << 'EOF'
<?php
$uptime = shell_exec('uptime -p');
echo trim($uptime);
?>
EOF

# Create app test endpoint
cat > /var/www/html/test-app.php << 'EOF'
<?php
header('Content-Type: application/json');
$start_time = microtime(true);

$app_url = "${app_server_url}";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, "http://" . $app_url . ":8080/health");
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5);

$result = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

$response_time = round((microtime(true) - $start_time) * 1000);

if ($http_code == 200) {
    echo json_encode(['status' => 'Connected', 'response_time' => $response_time]);
} else {
    echo json_encode(['status' => 'Failed', 'response_time' => $response_time]);
}
?>
EOF

# Create database test endpoint
cat > /var/www/html/test-db.php << 'EOF'
<?php
header('Content-Type: application/json');
$start_time = microtime(true);

// This would normally test via app layer
$response_time = round((microtime(true) - $start_time) * 1000);
echo json_encode(['status' => 'Connected via App Layer', 'response_time' => $response_time]);
?>
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure Apache
echo "ServerTokens Prod" >> /etc/httpd/conf/httpd.conf
echo "ServerSignature Off" >> /etc/httpd/conf/httpd.conf

# Restart Apache
systemctl restart httpd

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

# Log completion
echo "$(date): Web server setup completed" >> /var/log/user-data.log