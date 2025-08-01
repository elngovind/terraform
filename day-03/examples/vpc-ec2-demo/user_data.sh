#!/bin/bash
# User data script for web servers

# Update system
yum update -y

# Install Apache web server
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple web page
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>${project_name} - Terraform State Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        .container { background-color: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { color: #333; border-bottom: 2px solid #007acc; padding-bottom: 10px; }
        .info { margin: 20px 0; }
        .highlight { background-color: #e7f3ff; padding: 10px; border-left: 4px solid #007acc; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🚀 ${project_name} - Terraform State Management Demo</h1>
        
        <div class="info">
            <h2>Server Information</h2>
            <div class="highlight">
                <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
                <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
                <p><strong>Instance Type:</strong> <span id="instance-type">Loading...</span></p>
                <p><strong>Private IP:</strong> <span id="private-ip">Loading...</span></p>
                <p><strong>Public IP:</strong> <span id="public-ip">Loading...</span></p>
            </div>
        </div>

        <div class="info">
            <h2>Terraform State Demo Features</h2>
            <ul>
                <li>✅ Remote state management with S3 backend</li>
                <li>✅ State locking with DynamoDB</li>
                <li>✅ Multi-AZ VPC with public and private subnets</li>
                <li>✅ Application Load Balancer with Auto Scaling</li>
                <li>✅ Security groups and network ACLs</li>
                <li>✅ Infrastructure as Code best practices</li>
            </ul>
        </div>

        <div class="info">
            <h2>State Management Commands Demonstrated</h2>
            <div class="highlight">
                <code>
                    terraform state list<br>
                    terraform state show<br>
                    terraform state mv<br>
                    terraform state rm<br>
                    terraform import<br>
                    terraform refresh
                </code>
            </div>
        </div>

        <p><em>Generated at: $(date)</em></p>
    </div>

    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'N/A');

        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(() => document.getElementById('az').textContent = 'N/A');

        fetch('http://169.254.169.254/latest/meta-data/instance-type')
            .then(response => response.text())
            .then(data => document.getElementById('instance-type').textContent = data)
            .catch(() => document.getElementById('instance-type').textContent = 'N/A');

        fetch('http://169.254.169.254/latest/meta-data/local-ipv4')
            .then(response => response.text())
            .then(data => document.getElementById('private-ip').textContent = data)
            .catch(() => document.getElementById('private-ip').textContent = 'N/A');

        fetch('http://169.254.169.254/latest/meta-data/public-ipv4')
            .then(response => response.text())
            .then(data => document.getElementById('public-ip').textContent = data)
            .catch(() => document.getElementById('public-ip').textContent = 'N/A');
    </script>
</body>
</html>
EOF

# Create a health check endpoint
cat > /var/www/html/health << EOF
OK
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Configure Apache to start on boot
systemctl enable httpd

# Install CloudWatch agent (optional)
yum install -y amazon-cloudwatch-agent

# Log the completion
echo "$(date): Web server setup completed" >> /var/log/user-data.log