provider "aws" {
    region = "us-east-2"
}

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
                        "Region": "us-east-1"
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
