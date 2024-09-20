If you have a domain name from another provider like Hostinger, you can still perform **DNS validation** for your ACM certificate by manually adding the required DNS records to the provider's DNS management interface. Here's how you can achieve that:

### Steps for DNS Validation with a Third-Party Domain Provider:

1. **Request the ACM Certificate** in AWS.
2. **Retrieve DNS Validation Records** from AWS.
3. **Add DNS Records** to your domain provider (Hostinger in your case).
4. **Validate the Certificate** once the DNS records are propagated.

### Terraform Example for ACM DNS Validation:

1. **Request ACM Certificate**:
   - Use Terraform to request the ACM certificate with DNS validation.
   - Once requested, AWS will provide the DNS record that needs to be added to your domain provider (Hostinger).

```hcl
resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "yourdomain.com"  # Replace with your custom domain
  validation_method = "DNS"

  tags = {
    Name = "ALB ACM Certificate"
  }
}

# Output the DNS validation details, which you'll manually add to Hostinger DNS
output "acm_dns_validation" {
  value = aws_acm_certificate.acm_cert.domain_validation_options
}
```

2. **Add DNS Records in Hostinger**:

   - After running Terraform, it will output DNS validation details like the following:

   ```bash
   acm_dns_validation = [
     {
       "domain_name" = "yourdomain.com",
       "resource_record_name" = "_abcd1234.yourdomain.com.",
       "resource_record_type" = "CNAME",
       "resource_record_value" = "_validation-token.acm-validations.aws."
     }
   ]
   ```

   - Go to the DNS management panel in Hostinger, and add a **CNAME** record with:
     - **Name**: `resource_record_name` (e.g., `_abcd1234.yourdomain.com`)
     - **Type**: `CNAME`
     - **Value**: `resource_record_value` (e.g., `_validation-token.acm-validations.aws.`)
3. **Verify DNS Record Propagation**:

   - Once the DNS record is added, AWS will automatically verify it. This may take a few minutes.
4. **Validate ACM Certificate**:

   - If DNS validation is successful, AWS will issue the ACM certificate, which you can then use with your Application Load Balancer (ALB).

### Complete Terraform Example:

#### 1. Request the ACM Certificate:

```hcl
resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "yourdomain.com"  # Replace with your custom domain
  validation_method = "DNS"

  tags = {
    Name = "ALB ACM Certificate"
  }
}

# Output the DNS validation details
output "acm_dns_validation" {
  value = aws_acm_certificate.acm_cert.domain_validation_options
}
```

#### 2. ALB HTTPS Listener:

Once your ACM certificate is validated, attach it to your ALB with an HTTPS listener.

```hcl
# ALB HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.k8_workers_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.acm_cert.arn  # Use the validated ACM certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8_workers_alb_tg.arn
  }
}
```

### How to Add DNS Records in Hostinger:

1. Log in to Hostinger and navigate to the **DNS Zone Editor** for your domain.
2. Add a **CNAME** record with the values provided by the Terraform output (e.g., `_abcd1234.yourdomain.com` and `_validation-token.acm-validations.aws.`).
3. Save the DNS record and wait for it to propagate (usually 5-30 minutes).

After the DNS record propagates, AWS will automatically validate the certificate, and you can start using HTTPS with your ALB.
