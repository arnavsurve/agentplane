# 🚀 Glyfs Production Deployment Guide

**Critical Info for Asylum Ventures Client**

## Emergency Contacts
- **Primary**: Your phone number
- **Backup**: Your email
- **Server**: `ssh -i ~/.ssh/id_rsa ec2-user@52.8.122.166`

## 🚨 Emergency Procedures

### 1. Service Down - Quick Rollback
```bash
# SSH to server
ssh -i ~/.ssh/id_rsa ec2-user@52.8.122.166

# Execute emergency rollback
./scripts/rollback.sh

# Verify it's working
curl http://localhost:8080/health
```

### 2. Check Service Status
```bash
# Health check
curl http://52.8.122.166:8080/health

# Container status  
docker ps | grep glyfs-app

# View recent logs
docker logs glyfs-app --tail 50
```

### 3. Database Issues
```bash
# Check database connectivity
curl http://52.8.122.166:8080/api/auth/providers

# View database backups
aws rds describe-db-snapshots --db-instance-identifier glyfs-db-production
```

## 📊 Monitoring

### Automated Monitoring
- **GitHub Actions**: Checks every 5 minutes
- **Alerts**: Creates GitHub issues on failures
- **Slack**: Configure `SLACK_WEBHOOK_URL` in secrets

### Manual Health Checks
```bash
# Basic monitoring
./scripts/monitor.sh

# Load testing
./scripts/load-test.sh http://52.8.122.166:8080 10 60

# Backup verification
./scripts/verify-backups.sh
```

## 🔄 Deployment Process

### Automatic (Recommended)
1. Push to `main` branch
2. GitHub Actions builds and deploys
3. Automatic health checks
4. Rollback tagged for emergency use

### Manual Deployment
```bash
# Build and push image
docker build -t 662147645785.dkr.ecr.us-west-1.amazonaws.com/glyfs:manual .
docker push 662147645785.dkr.ecr.us-west-1.amazonaws.com/glyfs:manual

# Deploy on server
ssh -i ~/.ssh/id_rsa ec2-user@52.8.122.166
ECR_REGISTRY=662147645785.dkr.ecr.us-west-1.amazonaws.com \
ECR_REPOSITORY=glyfs \
IMAGE_TAG=manual \
AWS_REGION=us-west-1 \
./scripts/deploy-ecr.sh
```

## 📈 Performance Baselines

### Expected Performance (t3.micro)
- **Response Time**: < 200ms for health checks
- **Throughput**: > 20 requests/second
- **Uptime**: > 99.5%
- **Success Rate**: > 99%

### Scale-up Triggers
- Response time > 500ms consistently
- Success rate < 95%
- CPU usage > 80% for 10+ minutes

## 🛠️ Troubleshooting

### Common Issues

#### 1. Container Won't Start
```bash
# Check logs
docker logs glyfs-app

# Check environment
docker exec -it glyfs-app env | grep -E "(DATABASE_URL|JWT_SECRET)"

# Restart
docker restart glyfs-app
```

#### 2. Database Connection Issues
```bash
# Test database from server
telnet your-rds-endpoint 5432

# Check RDS status
aws rds describe-db-instances --db-instance-identifier glyfs-db-production
```

#### 3. Memory Issues
```bash
# Check memory usage
docker stats glyfs-app

# Check disk space
df -h
```

### When to Scale Up

#### Immediate Actions (< 1 hour)
- Change instance type in terraform: `t3.micro` → `t3.small`
- Apply: `terraform apply`

#### Short-term (< 1 day)  
- Add Application Load Balancer
- Multi-AZ deployment
- Separate database from app server

#### Medium-term (< 1 week)
- Auto-scaling groups
- Blue-green deployment
- Enhanced monitoring

## 💰 Cost Management

### Current Monthly Costs (~$50-100)
- EC2 t3.micro: ~$8.50
- RDS db.t3.micro: ~$12
- Data transfer: ~$5-15
- EBS storage: ~$2

### Cost Optimization
```bash
# Stop non-production resources
aws ec2 stop-instances --instance-ids i-xxxxx  # NAT instance
aws rds stop-db-instance --db-instance-identifier glyfs-db-production
```

## 📞 Support Escalation

### Level 1: Automatic
- GitHub Actions monitoring
- Auto-rollback on health check failure

### Level 2: Manual Intervention
- Run rollback script
- Check logs and metrics
- Restart services

### Level 3: Infrastructure Changes
- Scale up instance
- Database failover
- Contact AWS support

---

**Last Updated**: $(date)
**Asylum Ventures SLA**: 99.9% uptime, < 200ms response time
