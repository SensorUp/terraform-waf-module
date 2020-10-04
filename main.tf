# Source: https://github.com/awslabs/aws-waf-security-automations/blob/master/deployment/aws-waf-security-automations-webacl.template
resource "aws_wafv2_web_acl" "main" {
  name = "${local.name}wafACL"
  scope = var.scope

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled = true
    metric_name = "${local.name}wafACL"
  }

  default_action {
    type = var.defaultAction
  }

  rule {
    name = "${local.name}wafAWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafAWSManagedRulesCommonRuleSet"
      sampled_requests_enabled = true
    }
    statement {
      managed_rule_group_statement {
        name = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        // Rules: https://docs.aws.amazon.com/waf/latest/developerguide/aws-managed-rule-groups-list.html
        dynamic "excluded_rule" {
          for_each = var.excluded_rules
          content {
            name = excluded_rule.value
          }
        }
      }
    }
  }

  rule {
    name = "${local.name}wafWhitelistRule"
    priority = 1
    action {
      allow {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafWhitelistRule"
      sampled_requests_enabled = true
    }
    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WhitelistSetV4.arn
          }
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.WhitelistSetV6.arn
          }
        }
      }
    }
  }

  rule {
    name = "${local.name}wafBlacklistRule"
    priority = 2
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafBlacklistRule"
      sampled_requests_enabled = true
    }
    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.BlacklistSetIPV4.arn
          }
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.BlacklistSetIPV6.arn
          }
        }
      }
    }
  }

  rule {
    name = "${local.name}wafHttpFloodRegularRule"
    priority = 3
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafHttpFloodRegularRule"
      sampled_requests_enabled = true
    }
    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.HTTPFloodSetIPV4.arn
          }
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.HTTPFloodSetIPV6.arn
          }
        }
      }
    }
  }

  rule {
    name = "${local.name}wafHttpFloodRateBasedRule"
    priority = 4
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafHttpFloodRateBasedRule"
      sampled_requests_enabled = true
    }
    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit = var.requestThreshold
      }
    }
  }

  rule {
    name = "${local.name}wafScannersAndProbesRule"
    priority = 5
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafScannersAndProbesRule"
      sampled_requests_enabled = true
    }
    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.ScannersProbesSetIPV4.arn
          }
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.ScannersProbesSetIPV6.arn
          }
        }
      }
    }
  }

  rule {
    name = "${local.name}wafIPReputationListsRule"
    priority = 6
    action {
      block {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafIPReputationListsRule"
      sampled_requests_enabled = true
    }
    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.IPReputationListsSetIPV4.arn
          }
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.IPReputationListsSetIPV6.arn
          }
        }
      }
    }
  }

  rule {
    name = "${local.name}wafBadBotRule"
    priority = 7
    action {
      block {}
    }
    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafBadBotRule"
    }
    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.IPBadBotSetIPV4.arn
          }
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.IPBadBotSetIPV6.arn
          }
        }
      }
    }
  }

  rule {
    name = "${local.name}wafSqlInjectionRule"
    priority = 20
    action {
      block {}
    }
    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafSqlInjectionRule"
    }
    statement {
      or_statement {
        statement {
          sqli_match_statement {
            field_to_match {
              query_string {}
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
          sqli_match_statement {
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
          sqli_match_statement {
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
          sqli_match_statement {
            field_to_match {
              single_header {
                name = "Authorization"
              }
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
          sqli_match_statement {
            field_to_match {
              single_header {
                name = "Cookie"
              }
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
        }
      }
    }
  }
  rule {
    name = "${local.name}wafXssRule"
    priority = 30
    action {
      block {}
    }
    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "${local.name}wafXssRule"
    }
    statement {
      or_statement {
        statement {
          xss_match_statement {
            field_to_match {
              query_string {}
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
          xss_match_statement {
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
          xss_match_statement {
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }

          xss_match_statement {
            field_to_match {
              single_header {
                name = "Cookie"
              }
            }
            text_transformation {
              priority = 1
              type = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type = "HTML_ENTITY_DECODE"
            }
          }
        }
      }

    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.main.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
  redacted_fields {
    single_header {
      name = "authorizer"
    }
    single_header {
      name = "cookie"
    }
    single_header {
      name = "user-agent"
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = "aws-waf-logs-${local.name}"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.logging.arn
    bucket_arn = "arn:aws:s3:::${local.logging_bucket}"
    prefix     = "/AWSLogs/${local.account_id}/WAF/${local.region}/"
  }
}

resource "aws_iam_role" "logging" {
  name = "${local.name}-waf-stream-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy" "logging" {
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid":"CloudWatchAccess",
      "Action": [
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/kinesisfirehose/${local.name}-waf-stream:*"
      ],
      "Effect": "Allow"
    },
    {
      "Sid":"KinesisAccess",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords"
      ],
      "Resource": [
        "${aws_kinesis_firehose_delivery_stream.logging.arn}"
      ],
      "Effect": "Allow"
    },
    {
      "Sid":"S3Access",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.logging_bucket}",
        "arn:aws:s3:::${local.logging_bucket}/*"
      ],
      "Effect": "Allow"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "logging" {
role       = aws_iam_role.logging.name
policy_arn = aws_iam_policy.logging.arn
}

