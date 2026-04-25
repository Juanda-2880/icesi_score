const apiBaseUrl = 'https://3ypqilfuh3.execute-api.us-east-2.amazonaws.com';

const amplifyconfig = ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "us-east-2_JqDfPZo3W",
                        "AppClientId": "6tj4cr9h6dksiouc8q9il1ctpo",
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
