
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/express-gateway-app"
  retention_in_days = var.log_retention_in_days

  tags = var.additional_tags
}

# IAM Execution Role
resource "aws_iam_role" "execution" {
  name = "ecs-express-gateway-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.additional_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "ecs-execution-secrets-policy"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          for secret_arn in values(var.application_env_secrets) : secret_arn
        ]
      }
    ]
  })
}

# IAM Infrastructure Role
resource "aws_iam_role" "infrastructure" {
  name = "ecs-express-gateway-infrastructure-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.additional_tags
}

# ECS Express Gateway Service
resource "aws_ecs_express_gateway_service" "example" {
  execution_role_arn      = aws_iam_role.execution.arn
  infrastructure_role_arn = aws_iam_role.infrastructure.arn
  health_check_path       = "/health"

  primary_container {
    image          = var.application_image
    container_port = var.application_port
    command        = ["./start.sh"]

    aws_logs_configuration {
      log_group = aws_cloudwatch_log_group.app.name
    }

    dynamic "environment" {
      for_each = var.application_env_vars
      content {
        name  = environment.key
        value = environment.value
      }
    }

    # Always include PORT environment variable
    environment {
      name  = "PORT"
      value = var.application_port
    }

    dynamic "secret" {
      for_each = var.application_env_secrets
      content {
        name       = secret.key
        value_from = secret.value
      }
    }
  }

  tags = var.additional_tags
}
