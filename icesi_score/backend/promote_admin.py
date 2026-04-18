import json
import boto3
import os

# Inicializamos el cliente de Cognito
client = boto3.client('cognito-idp')
USER_POOL_ID = os.environ['USER_POOL_ID']
SUPER_ADMIN_EMAIL = "admin@uicesi.edu.co"

def lambda_handler(event, context):
    try:
        # 1. Extraer los datos del usuario que hace la petición (desde el API Gateway)
        claims = event['requestContext']['authorizer']['claims']
        requester_email = claims.get('email')
        
        # 2. Seguridad de Backend: Verificar si es el Super Admin (User Created)
        if requester_email != SUPER_ADMIN_EMAIL:
            return {
                'statusCode': 403,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps('Acceso denegado: Solo el Administrador Principal puede gestionar otros administradores.')
            }

        # 3. Determinar la acción a realizar
        http_method = event['requestContext']['http']['method']
        
        if http_method == 'GET':
            # Listar administradores
            response = client.list_users_in_group(
                UserPoolId=USER_POOL_ID,
                GroupName='Admins'
            )
            users = []
            for user in response.get('Users', []):
                email = next((attr['Value'] for attr in user['Attributes'] if attr['Name'] == 'email'), None)
                if email:
                    users.append({
                        'username': user['Username'],
                        'email': email,
                        'enabled': user['Enabled'],
                        'status': user['UserStatus'],
                        'created': str(user['UserCreateDate'])
                    })
            
            return {
                'statusCode': 200,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                },
                'body': json.dumps(users)
            }

        elif http_method == 'POST':
            body = json.loads(event.get('body', '{}'))
            action = body.get('action', 'add')
            target_email = body.get('email')

            if not target_email:
                return {
                    'statusCode': 400,
                    'headers': {
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                    },
                    'body': json.dumps('Falta el email del usuario.')
                }

            if action == 'add':
                # Promover a Admin
                client.admin_add_user_to_group(
                    UserPoolId=USER_POOL_ID,
                    Username=target_email,
                    GroupName='Admins'
                )
                return {
                    'statusCode': 200,
                    'headers': {
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                    },
                    'body': json.dumps(f'¡Éxito! El usuario {target_email} ahora es Administrador.')
                }
            
            elif action == 'remove':
                # No permitir auto-eliminarse
                if target_email == SUPER_ADMIN_EMAIL:
                    return {
                        'statusCode': 400,
                        'headers': {
                            'Access-Control-Allow-Origin': '*',
                            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                        },
                        'body': json.dumps('No se puede eliminar al Administrador Principal.')
                    }
                
                # Quitar de grupo Admins
                client.admin_remove_user_from_group(
                    UserPoolId=USER_POOL_ID,
                    Username=target_email,
                    GroupName='Admins'
                )
                return {
                    'statusCode': 200,
                    'headers': {
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                        'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
                    },
                    'body': json.dumps(f'¡Éxito! El usuario {target_email} ya no es Administrador.')
                }

        return {
            'statusCode': 405,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps('Método no permitido.')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,Authorization',
                'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
            },
            'body': json.dumps(f'Error interno: {str(e)}')
        }
