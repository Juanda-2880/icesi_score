const amplifyconfig = ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-2_V5MKKHd6Y",
                        "AppClientId": "1kho6a6r46fl0au8ln8l25fs73",
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
