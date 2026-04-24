# ── CloudWatch Logs ──────────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "agent" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 7

  tags = { Project = var.app_name }
}

# ── Secrets Manager (referencias — créalos manualmente antes del primer deploy) ──
data "aws_secretsmanager_secret" "openai" {
  name = "openai-api-key"
}

data "aws_secretsmanager_secret" "langchain" {
  name = "langchain-api-key"
}

# ── IAM ──────────────────────────────────────────────────────────────────────
resource "aws_iam_role" "ecs_execution" {
  name = "${var.app_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Permiso para leer los secrets
resource "aws_iam_role_policy" "secrets_access" {
  name = "${var.app_name}-secrets-access"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        data.aws_secretsmanager_secret.openai.arn,
        data.aws_secretsmanager_secret.langchain.arn,
      ]
    }]
  })
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "ecs_task" {
  name        = "${var.app_name}-ecs-sg"
  description = "Permite trafico entrante en 8501 y salida total"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Streamlit"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Salida total"
  }

  tags = { Project = var.app_name }
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Project = var.app_name }
}

# ── Task Definition ───────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "agent" {
  family                   = var.app_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([{
    name  = var.app_name
    image = "${aws_ecr_repository.agent.repository_url}:${var.image_tag}"

    portMappings = [{
      containerPort = 8501
      protocol      = "tcp"
    }]

    environment = [
      { name = "LANGCHAIN_TRACING_V2", value = "true" },
      { name = "LANGCHAIN_PROJECT",    value = var.app_name },
      { name = "LANGCHAIN_ENDPOINT",   value = "https://eu.api.smith.langchain.com" },
    ]

    secrets = [
      {
        name      = "OPENAI_API_KEY"
        valueFrom = data.aws_secretsmanager_secret.openai.arn
      },
      {
        name      = "LANGCHAIN_API_KEY"
        valueFrom = data.aws_secretsmanager_secret.langchain.arn
      },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.agent.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    essential = true
  }])

  tags = { Project = var.app_name }
}

# ── ECS Service ───────────────────────────────────────────────────────────────
resource "aws_ecs_service" "agent" {
  name            = "${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.agent.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_task.id]
    assign_public_ip = true
  }

  # Permite actualizar la imagen sin recrear el servicio
  force_new_deployment = true

  tags = { Project = var.app_name }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.agent.name
}

output "app_note" {
  value = "Una vez desplegado, busca la IP publica del task en ECS > Clusters > ${aws_ecs_cluster.main.name} > Tasks"
}
