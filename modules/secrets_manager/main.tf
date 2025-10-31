resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "nutriveda-db-credentials-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  description             = "Database credentials for NutriVeda"
  recovery_window_in_days = 0

  tags = {
    Name        = "nutriveda-db-credentials"
    Environment = "production"
    ManagedBy   = "OpenTofu"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "postgres"
    password = var.db_password
  })
}