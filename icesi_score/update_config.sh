#!/bin/bash

TF_DIR="./infrastructure"
FLUTTER_FILE="./mobile/lib/amplifyconfiguration.dart"
REGION="us-east-2" 

echo " Obteniendo credenciales desde Terraform..."
cd $TF_DIR || exit
POOL_ID=$(terraform output -raw cognito_user_pool_id)
CLIENT_ID=$(terraform output -raw cognito_client_id)

cd ..

if [ -z "$POOL_ID" ] || [ -z "$CLIENT_ID" ]; then
    echo " Error: No se pudieron obtener los outputs. ¿Ya hiciste 'terraform apply'?"
    exit 1
fi

echo " IDs obtenidos:"
echo "   - Pool ID: $POOL_ID"
echo "   - Client ID: $CLIENT_ID"
echo " Escribiendo en $FLUTTER_FILE..."


cat <<EOF > $FLUTTER_FILE
const amplifyconfig = ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "$POOL_ID",
                        "AppClientId": "$CLIENT_ID",
                        "Region": "$REGION"
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
EOF

echo " ¡Archivo actualizado con éxito! Ya puedes probar en Flutter."