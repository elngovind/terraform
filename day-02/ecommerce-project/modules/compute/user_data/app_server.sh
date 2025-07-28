#!/bin/bash
yum update -y
yum install -y java-11-amazon-corretto-headless

# Create application directory
mkdir -p /opt/ecommerce-app
cd /opt/ecommerce-app

# Create a simple Java application
cat <<'EOF' > App.java
import java.io.*;
import java.net.*;
import java.util.concurrent.*;

public class App {
    public static void main(String[] args) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", new AppHandler());
        server.setExecutor(Executors.newCachedThreadPool());
        server.start();
        System.out.println("Application server started on port 8080");
    }
    
    static class AppHandler implements HttpHandler {
        public void handle(HttpExchange exchange) throws IOException {
            String response = "{\n" +
                "  \"status\": \"healthy\",\n" +
                "  \"service\": \"ecommerce-app\",\n" +
                "  \"environment\": \"${environment}\",\n" +
                "  \"timestamp\": \"" + new java.util.Date() + "\",\n" +
                "  \"tier\": \"application\"\n" +
                "}";
            
            exchange.getResponseHeaders().set("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}
EOF

# Compile and run the application
javac App.java
nohup java App > /var/log/ecommerce-app.log 2>&1 &

# Create systemd service
cat <<'EOF' > /etc/systemd/system/ecommerce-app.service
[Unit]
Description=E-Commerce Application Server
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/ecommerce-app
ExecStart=/usr/bin/java App
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable ecommerce-app
systemctl start ecommerce-app