import json
import boto3
import os

# Inicializamos el cliente de Cognito
client = boto3.client('cognito-idp')
USER_POOL_ID = os.environ['USER_POOL_ID']

def lambda_handler(event, context):
    try:
        # 1. Extraer los datos del usuario que hace la petición (desde el API Gateway)
        claims = event['requestContext']['authorizer']['claims']
        groups = claims.get('cognito:groups', '')

        # 2. Seguridad de Backend: Verificar si es Admin
        if 'Admins' not in groups:
            return {
                'statusCode': 403,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps('Acceso denegado: Solo los administradores pueden promover a otros usuarios.')
            }

        # 3. Leer el correo del usuario al que queremos promover
        body = json.loads(event.get('body', '{}'))
        target_username = body.get('email')

        if not target_username:
            return {
                'statusCode': 400,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps('Falta el email del usuario a promover.')
            }

        # 4. Ejecutar el comando de promoción en Cognito
        client.admin_add_user_to_group(
            UserPoolId=USER_POOL_ID,
            Username=target_username,
            GroupName='Admins'
        )

        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps(f'¡Éxito! El usuario {target_username} ahora es Administrador.')
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps(f'Error interno: {str(e)}')
        }