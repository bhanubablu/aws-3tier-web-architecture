# IAM Role for EC2 Instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS SSM Policy for secure terminal access without SSH keys
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent Policy for system metrics
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Find latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Launch Template for App Tier
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              apt-get update -y
              apt-get install -y python3-pip python3-venv git curl

              # Setup application directory
              mkdir -p /opt/webapp
              cd /opt/webapp

              # Create VirtualEnv & Install Flask + PyMySQL
              python3 -m venv venv
              source venv/bin/activate
              pip install --upgrade pip
              pip install flask pymysql gunicorn

              # Write Flask App
              cat << 'APP_EOF' > /opt/webapp/app.py
              import os
              import socket
              from flask import Flask, jsonify

              app = Flask(__name__)

              @app.route('/')
              def index():
                  hostname = socket.gethostname()
                  return jsonify({
                      "status": "healthy",
                      "tier": "Application Tier (Backend Microservice)",
                      "architecture": "AWS 3-Tier Highly Available",
                      "hostname": hostname,
                      "author": "Boddu Bhanu Prakash",
                      "database_host": os.getenv("DB_HOST", "rds-mysql-cluster")
                  })

              @app.route('/health')
              def health():
                  return jsonify({"status": "UP", "code": 200}), 200

              if __name__ == '__main__':
                  app.run(host='0.0.0.0', port=5000)
              APP_EOF

              # Create systemd service for Gunicorn
              cat << 'SERVICE_EOF' > /etc/systemd/system/webapp.service
              [Unit]
              Description=3-Tier App Gunicorn Service
              After=network.target

              [Service]
              User=root
              WorkingDirectory=/opt/webapp
              Environment="PATH=/opt/webapp/venv/bin"
              Environment="DB_HOST=${aws_db_instance.rds.endpoint}"
              ExecStart=/opt/webapp/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 app:app
              Restart=always

              [Install]
              WantedBy=multi-user.target
              SERVICE_EOF

              systemctl daemon-reload
              systemctl enable webapp
              systemctl start webapp
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-app-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.project_name}-asg-"
  vpc_zone_identifier = aws_subnet.app[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size     = var.asg_min_size
  max_size     = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-worker"
    propagate_at_launch = true
  }
}

# Target Tracking Scaling Policy (Maintain 70% CPU)
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-cpu-target-policy"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}
