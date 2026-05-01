const apiBaseUrl = 'https://3sul37mrw3.execute-api.us-east-2.amazonaws.com';

const amplifyconfig = ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-2_rTDIFXuTC",
                        "AppClientId": "1kte5tiich07hrk4h7i3fp741s",
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
