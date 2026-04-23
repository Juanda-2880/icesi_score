const apiBaseUrl = 'https://eobbg4aof2.execute-api.us-east-2.amazonaws.com';

const amplifyconfig = ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-2_j2PbkbsZc",
                        "AppClientId": "1c3g8tjf8tlng20tiu68gbesl8",
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
