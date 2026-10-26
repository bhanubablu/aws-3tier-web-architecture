import os
import socket
from datetime import datetime
from flask import Flask, jsonify, request, render_template_string
import pymysql

app = Flask(__name__)

# Database configuration from environment variables
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASS = os.getenv("DB_PASSWORD", "SecureCloudPass2025!")
DB_NAME = os.getenv("DB_NAME", "appdb")

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>AWS 3-Tier Web Architecture Demo</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 40px; }
    .card { background: #1e293b; border-radius: 12px; padding: 30px; max-width: 700px; margin: 0 auto; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
    h1 { color: #38bdf8; margin-top: 0; font-size: 24px; }
    .badge { display: inline-block; padding: 4px 10px; border-radius: 9999px; font-size: 12px; font-weight: 600; background: #0369a1; color: #e0f2fe; margin-bottom: 20px; }
    .info-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #334155; font-size: 14px; }
    .info-label { color: #94a3b8; }
    .info-val { font-weight: 600; color: #38bdf8; font-family: monospace; }
    .status-ok { color: #4ade80; font-weight: bold; }
    .footer { margin-top: 25px; text-align: center; color: #64748b; font-size: 13px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">AWS Cloud Architecture Live Demo</div>
    <h1>Highly Available 3-Tier Web Application</h1>
    <p>This web application is running across an Auto Scaling Group in private subnets, behind an Application Load Balancer.</p>
    
    <div class="info-row">
      <span class="info-label">Engineer</span>
      <span class="info-val">Boddu Bhanu Prakash</span>
    </div>
    <div class="info-row">
      <span class="info-label">Host Node / EC2 Instance ID</span>
      <span class="info-val">{{ hostname }}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Database Status</span>
      <span class="info-val {{ db_class }}">{{ db_status }}</span>
    </div>
    <div class="info-row">
      <span class="info-label">Server Timestamp (UTC)</span>
      <span class="info-val">{{ timestamp }}</span>
    </div>
    <div class="footer">
      Deployed with Terraform & AWS Well-Architected Framework
    </div>
  </div>
</body>
</html>
"""

def get_db_status():
    try:
        conn = pymysql.connect(
            host=DB_HOST.split(":")[0],
            user=DB_USER,
            password=DB_PASS,
            database=DB_NAME,
            connect_timeout=2
        )
        conn.close()
        return "Connected (Multi-AZ RDS MySQL)", "status-ok"
    except Exception as e:
        return f"Standby / Inactive ({str(e)[:30]}...)", "info-label"

@app.route("/")
def home():
    hostname = socket.gethostname()
    db_status, db_class = get_db_status()
    timestamp = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    return render_template_string(HTML_TEMPLATE, hostname=hostname, db_status=db_status, db_class=db_class, timestamp=timestamp)

@app.route("/health")
def health():
    return jsonify({
        "status": "UP",
        "code": 200,
        "instance": socket.gethostname(),
        "timestamp": datetime.utcnow().isoformat()
    }), 200

@app.route("/api/info")
def info():
    return jsonify({
        "project": "Highly Available 3-Tier Web Architecture on AWS",
        "architect": "Boddu Bhanu Prakash",
        "tier": "Application Tier (Microservice)",
        "network": "Private VPC App Subnet",
        "load_balancer": "Application Load Balancer (ALB)",
        "database": "Amazon RDS MySQL Multi-AZ"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

