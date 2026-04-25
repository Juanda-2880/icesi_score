-- Fix superadmin: replace admin@uicesi.edu.co with superadmin@uicesi.edu.co
-- Run AFTER creating superadmin@uicesi.edu.co in Cognito and obtaining the sub.
-- Replace <SUB_DE_COGNITO> with the actual UUID from: aws cognito-idp admin-get-user ...

DELETE FROM app_users WHERE email = 'admin@uicesi.edu.co';

INSERT INTO app_users (id, full_name, email, phone, university, role)
VALUES (
  'e15b5530-60f1-70e6-76de-d5f9384bcb4a',
  'Super Admin Icesi',
  'superadmin@uicesi.edu.co',
  '+57 300 000 0000',
  'Universidad Icesi',
  'SUPERADMIN'
) ON CONFLICT (email) DO UPDATE SET role = 'SUPERADMIN';
