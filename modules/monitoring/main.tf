########################
# CloudWatch Metrics Filter
########################

# Define CloudWatch Metric Filter for SSH Failures
resource "aws_cloudwatch_log_metric_filter" "ssh_failures" {
  for_each       = { for i, s in var.ec2.instance_ids : i => s }
  name           = "${var.common.env}-metrics-filter-ssh-failures-${each.key}"
  pattern        = "[Mon, day, timestamp, ip, id, msg1= Failed, msg2 = password, ...]"
  log_group_name = "/var/log/secure-${each.key}"
  metric_transformation {
    name          = "SSH-Failures-${each.key}"
    namespace     = "CWAgent"
    value         = "1"
    default_value = "0"
  }
}

# Define CloudWatch Metric Filter for SSH during non-business hours
resource "aws_cloudwatch_log_metric_filter" "ssh_non_business_hours" {
  for_each       = { for i, s in var.ec2.instance_ids : i => s }
  name           = "${var.common.env}-metrics-filter-ssh-during-non-business-hours-${each.key}"
  pattern        = "[Mon, day, timestamp=%1[2-9]\\:[0-5][0-9]\\:[0-5][0-9]% || timestamp=%2[0-1]\\:[0-5][0-9]\\:[0-5][0-9]%, ip, id, msg1= Accepted, msg2 = publickey, ...]"
  log_group_name = "/var/log/secure-${each.key}"
  metric_transformation {
    name          = "SSH-during-non-business-hours-${each.key}"
    namespace     = "CWAgent"
    value         = "1"
    default_value = "0"
  }
}

########################
# CloudWatch Alarm
########################

# Define CloudWatch Alarm for CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  for_each    = { for i, s in var.ec2.instance_ids : i => s }
  alarm_name  = "${var.common.env}-alarm-cpu-utilization-${each.key}"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  dimensions = {
    InstanceId = each.value
  }
  statistic           = "Average"
  period              = 300
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 80
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "breaching"
  alarm_description   = "This metric monitors EC2 instance CPU utilization."
  alarm_actions       = [aws_sns_topic.main.arn]
  tags = {
    Name = "${var.common.env}-alarm-cpu-utilization-${each.key}"
  }
}

# Define CloudWatch Alarm for Memory Utilization
resource "aws_cloudwatch_metric_alarm" "memory_utilization" {
  for_each    = { for i, s in var.ec2.instance_ids : i => s }
  alarm_name  = "${var.common.env}-alarm-memory-utilization-${each.key}"
  namespace   = "CWAgent"
  metric_name = "mem_used_percent"
  dimensions = {
    InstanceId = each.value
  }
  statistic           = "Average"
  period              = 300
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 80
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  treat_missing_data  = "breaching"
  alarm_description   = "This metric monitors EC2 instance memory utilization."
  alarm_actions       = [aws_sns_topic.main.arn]
  tags = {
    Name = "${var.common.env}-alarm-memory-utilization-${each.key}"
  }
}

# Define CloudWatch Alarm for Disk Utilization
resource "aws_cloudwatch_metric_alarm" "disk_utilization" {
  for_each    = { for i, s in var.ec2.instance_ids : i => s }
  alarm_name  = "${var.common.env}-alarm-disk-utilization-${each.key}"
  namespace   = "CWAgent"
  metric_name = "disk_used_percent"
  dimensions = {
    InstanceId = each.value
    device     = "nvme0n1p4"
    fstype     = "xfs"
    path       = "/"
  }
  statistic           = "Average"
  period              = 300
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 80
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "breaching"
  alarm_description   = "This metric monitors EC2 instance disk utilization."
  alarm_actions       = [aws_sns_topic.main.arn]
  tags = {
    Name = "${var.common.env}-alarm-disk-utilization-${each.key}"
  }
}

# Define CloudWatch Alarm for SSH Failures
resource "aws_cloudwatch_metric_alarm" "ssh_failures" {
  for_each            = { for i, s in aws_cloudwatch_log_metric_filter.ssh_failures : i => s }
  alarm_name          = "${var.common.env}-alarm-ssh-failures-${each.key}"
  namespace           = "CWAgent"
  metric_name         = "SSH-Failures-${each.key}"
  statistic           = "Sum"
  period              = 60
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 10
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors SSH failures."
  alarm_actions       = [aws_sns_topic.main.arn]
  tags = {
    Name = "${var.common.env}-alarm-ssh-failures-${each.key}"
  }
}

# Define CloudWatch Alarm for SSH during non-business hours
resource "aws_cloudwatch_metric_alarm" "ssh_non_business_hours" {
  for_each            = { for i, s in aws_cloudwatch_log_metric_filter.ssh_non_business_hours : i => s }
  alarm_name          = "${var.common.env}-alarm-ssh-non-business-hours-${each.key}"
  namespace           = "CWAgent"
  metric_name         = "SSH-during-non-business-hours-${each.key}"
  statistic           = "Sum"
  period              = 60
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "This metric monitors SSH logins during non-business hours."
  alarm_actions       = [aws_sns_topic.main.arn]
  tags = {
    Name = "${var.common.env}-alarm-ssh-non-business-hours-${each.key}"
  }
}

########################
# SNS
########################

# Define SNS Topic
resource "aws_sns_topic" "main" {
  name = "${var.common.env}-sns-topic"
  tags = {
    Name = "${var.common.env}-sns-topic"
  }
}

# Define SNS Topic Subscription
resource "aws_sns_topic_subscription" "main" {
  for_each  = toset(var.target.email_addresses)
  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = each.key
}

# Define SNS Topic Policy
data "aws_iam_policy_document" "sns-topic" {
  statement {
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.main.arn]
    effect    = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
  }
}

# Associate SNS Topic Policy
resource "aws_sns_topic_policy" "main" {
  arn    = aws_sns_topic.main.arn
  policy = data.aws_iam_policy_document.sns-topic.json
}
