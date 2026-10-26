# Highly Available 3-Tier Web Application Architecture on AWS

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4.svg?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900.svg?logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An end-to-end, production-ready **3-Tier Cloud Architecture** deployed on Amazon Web Services (AWS) using **Terraform (Infrastructure as Code)**. Designed with high availability, strict security isolation, auto-scaling, and the **AWS Well-Architected Framework**.

---

## 📌 Architecture Diagram

```
                        [ Internet Users ]
                                |
                                v
                   [ Internet Gateway (IGW) ]
                                |
======================= PUBLIC SUBNETS (AZ-a & AZ-b) =======================
|                                                                          |
|               [ Application Load Balancer (ALB) ]                        |
|                                |                                         |
|                  [ NAT Gateway (AZ-a) ]                                  |
============================================================================
                                |
                   (Traffic forwarded securely)
                                |
==================== PRIVATE APP SUBNETS (AZ-a & AZ-b) ====================
|                                                                          |
|       [ Auto Scaling Group (EC2 Instances: Min 2, Max 6) ]               |
|            - Running Python Flask REST Application                       |
|            - Dynamic Scaling on CPU Utilization                          |
|                                                                          |
============================================================================
                                |
                   (MySQL Port 3306 ONLY)
                                |
================== PRIVATE DATABASE SUBNETS (AZ-a & AZ-b) ==================
|                                                                          |
|             [ Multi-AZ Amazon RDS (MySQL 8.0) ]                          |
|         Primary Database (AZ-a) <---> Standby Replica (AZ-b)             |
|                                                                          |
============================================================================
                                |
              [ AWS CloudWatch Dashboards & Alarms ]
```

---

## 🌟 Key Highlights & Design Decisions

1. **True 3-Tier Separation:**
   - **Tier 1 (Presentation):** Application Load Balancer in public subnets receives incoming web traffic on HTTP/HTTPS.
   - **Tier 2 (Application):** EC2 instances run inside private subnets without public IPs. They can only receive traffic from the ALB. Outbound internet access for software updates is routed through an AWS NAT Gateway.
   - **Tier 3 (Database):** Amazon RDS MySQL runs inside isolated private database subnets with zero internet routing. Port 3306 is open **only** to the EC2 application security group.
2. **High Availability (99.95%):**
   - Deployed across two separate AWS Availability Zones (`us-east-1a` and `us-east-1b`).
   - If one data center has an outage, the system continues running with zero downtime.
3. **Dynamic Auto-Scaling:**
   - Auto Scaling Group automatically adjusts capacity between 2 and 6 EC2 instances based on real-time CPU usage.
4. **CloudWatch Monitoring & Alarms:**
   - Metric alarms monitor high CPU (>75%) and ALB 5XX error spikes.
   - Custom CloudWatch dashboard provides real-time system visibility.

---

## 📁 Repository Structure

```
.
├── terraform/
│   ├── main.tf              # Provider and AWS configurations
│   ├── variables.tf         # Configurable parameters (region, CIDRs, sizes)
│   ├── vpc.tf               # VPC, 6 subnets, IGW, NAT Gateway, Route Tables
│   ├── security_groups.tf   # Strict least-privilege security groups
│   ├── alb.tf               # Application Load Balancer & target groups
│   ├── asg.tf               # Auto Scaling Group, Launch Template & IAM
│   ├── rds.tf               # Multi-AZ RDS MySQL database instance
│   ├── cloudwatch.tf        # Alarms and operational dashboard
│   └── outputs.tf           # Output endpoints (ALB DNS, DB host)
├── app/
│   ├── app.py               # Flask application with health checks
│   └── requirements.txt     # Python dependencies
└── README.md
```

---

## 🚀 How to Deploy on AWS

### Prerequisites
- [AWS CLI](https://aws.amazon.com/cli/) configured with valid credentials (`aws configure`).
- [Terraform](https://developer.hashicorp.com/terraform/downloads) v1.5+ installed.

### Step 1: Clone the Repository
```bash
git clone https://github.com/bhanubablu/aws-3tier-web-architecture.git
cd aws-3tier-web-architecture/terraform
```

### Step 2: Initialize & Review Terraform
```bash
# Initialize Terraform AWS provider
terraform init

# Review execution plan
terraform plan
```

### Step 3: Apply Infrastructure
```bash
terraform apply -auto-approve
```
*Terraform will provision the complete VPC, subnets, NAT gateway, ALB, ASG, RDS, and CloudWatch alarms in ~8-12 minutes.*

### Step 4: Verify Deployment
Once Terraform finishes, it outputs the `alb_dns_name`:
```bash
curl http://<alb_dns_name>/health
```
Open `http://<alb_dns_name>` in your browser to view the live dashboard!

### Step 5: Clean Up (Destroy Resources to avoid AWS charges)
```bash
terraform destroy -auto-approve
```

---

## 🎤 Interview Cheat Sheet (Easy to Speak & Pronounce)

When interviewers ask you: *"Can you walk me through your 3-Tier AWS Architecture project?"*

Here are simple, clear answers you can speak with confidence:

1. **"What is the main goal of this architecture?"**
   > *"The goal is to build a reliable and secure web app setup on AWS. I divided it into three separate layers: public load balancers, private application servers, and private database servers across two availability zones so there is no single point of failure."*

2. **"Why did you place EC2 instances in private subnets?"**
   > *"For security. Backend application servers do not need public IP addresses. By placing them in private subnets, no one on the public internet can attack or access them directly. All traffic must pass through the Application Load Balancer."*

3. **"How do the private EC2 instances download packages or updates?"**
   > *"I set up an AWS NAT Gateway in the public subnet. The private instances send outbound traffic through the NAT Gateway to the Internet, but incoming traffic from the outside world is blocked."*

4. **"How does Multi-AZ RDS work?"**
   > *"Multi-AZ creates a primary database in one availability zone and a synchronous standby replica in a second availability zone. If the primary database ever fails, AWS automatically switches to the standby replica with zero data loss."*

5. **"How does the load balancer know if an EC2 server is healthy?"**
   > *"The ALB sends an HTTP ping every 30 seconds to the `/health` endpoint on port 5000. If an instance fails 3 consecutive health checks, the load balancer stops sending it traffic and the Auto Scaling Group replaces it with a new healthy instance."*

---

## 👨‍💻 Author
**Boddu Bhanu Prakash**  
- B.Tech in Electronics and Communication Engineering, **IIIT Dharwad (2021 – 2025)**  
- Email: [boddubhanuprakash7@gmail.com](mailto:boddubhanuprakash7@gmail.com)  
- LinkedIn: [linkedin.com/in/boddu-bhanu-prakash](https://www.linkedin.com/in/boddu-bhanu-prakash-b5309034b)  
- GitHub: [github.com/bhanubablu](https://github.com/bhanubablu)

