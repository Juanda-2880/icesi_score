resource "aws_cognito_user_pool" "icesi_score_pool" {
  name = "icesi-score-users"

  username_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  tags = {
    Project     = "SofaScoreUniversitario"
    Environment = "Dev"
  }
}

resource "aws_cognito_user_pool_client" "flutter_app_client" {
  name         = "icesi-score-flutter-client"
  user_pool_id = aws_cognito_user_pool.icesi_score_pool.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.icesi_score_pool.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.flutter_app_client.id
}

resource "local_file" "amplify_config_dart" {

  filename = "../lib/amplifyconfiguration.dart"
  content = <<-EOT
const amplifyconfig = ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "${aws_cognito_user_pool.icesi_score_pool.id}",
                        "AppClientId": "${aws_cognito_user_pool_client.flutter_app_client.id}",
                        "Region": "us-east-2"
                    }
                },
                "Auth": {
                    "Default": {
                        "authenticationFlowType": "USER_SRP_AUTH"
                    }
                }
            }
        }
    }
}''';
  EOT
}

resource "aws_cognito_user_group" "admins_group" {
  name         = "Admins"
  user_pool_id = aws_cognito_user_pool.icesi_score_pool.id
  description  = "Administradores de la plataforma SofaScore (Profesores/Organizadores)"
  
}


resource "aws_cognito_user_group" "students_group" {
  name         = "Estudiantes"
  user_pool_id = aws_cognito_user_pool.icesi_score_pool.id
  description  = "Usuarios regulares de la aplicación"
}

# 1. Crear el usuario Administrador base
resource "aws_cognito_user" "super_admin" {
  user_pool_id = aws_cognito_user_pool.icesi_score_pool.id
  username     = "admin@uicesi.edu.co"
  
  attributes = {
    email          = "admin@uicesi.edu.co"
    email_verified = true
  }
  
  # Contraseña inicial (Cognito podría pedirte cambiarla al primer login, 
  # pero en nuestro flujo funcionará para pruebas)
  password = "SuperPassword123!" 
}

# 2. Meter a ese usuario en el grupo de Admins
resource "aws_cognito_user_in_group" "super_admin_membership" {
  user_pool_id = aws_cognito_user_pool.icesi_score_pool.id
  group_name   = aws_cognito_user_group.admins_group.name
  username     = aws_cognito_user.super_admin.username
}
