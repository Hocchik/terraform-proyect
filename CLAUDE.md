# Proyecto-Terraform: IaC para 50 sucursales

## Contexto
Reto de equipo del curso de Servicios Cloud (UTP). Caso: 50 sucursales con un patrón común. Cada sede requiere red, 2 VMs, reglas de seguridad y monitoreo. AWS y GCP deben usar el mismo proceso de aprobación. Los secretos no pueden estar en el repositorio. Ocurrió un cambio urgente manual en producción (drift).
Entregables a justificar en la sustentación: repositorio, módulos, state, pipeline y tratamiento del drift, indicando qué herramienta se usa en cada etapa.

## Nuestro enfoque (versión práctica y gratuita)
- Cuenta AWS con plan Free (créditos limitados, la cuenta se cierra al vencer). Región única: us-east-2.
- Costo objetivo: $0. Solo 1 o 2 sucursales reales en AWS; las 50 se demuestran con LocalStack.
- Para GCP: solo un módulo documentado o un plan. El foco es que el pipeline y la aprobación sean idénticos en ambas nubes.

## Restricciones de costo (obligatorias)
- PROHIBIDO crear NAT Gateway, Elastic IP sin uso, RDS/Aurora, Load Balancers, Bedrock o cualquier servicio que cobre por hora sin necesidad.
- Instancias EC2 solo t3.micro (o t2.micro). Subredes públicas, sin NAT.
- Secretos en SSM Parameter Store (SecureString), no en Secrets Manager.
- Todo recurso lleva tags: Proyecto=iac-sucursales, Sucursal=<nombre>, Entorno=practica.
- Al terminar cada sesión de pruebas se hace terraform destroy.

## Reglas de seguridad y trabajo
- NUNCA ejecutes terraform apply ni terraform destroy. Yo los ejecuto después de leer el plan. Tú puedes correr terraform fmt, validate y plan solo si te lo pido.
- No leas, muestres ni escribas credenciales de AWS. No toques la carpeta .aws ni archivos .csv de claves.
- Nada de secretos en el código ni en archivos .tfvars versionados. Respeta el .gitignore.
- Antes de cada commit, verifica que no haya secretos.
- Hazlo por fases, una a la vez, y espera mi confirmación antes de pasar a la siguiente.
- Código simple, comentado en lo esencial, sin sobreingeniería. Cada módulo con variables.tf (con descripciones), outputs.tf y un README corto.

## Stack
Terraform (>= 1.10, backend S3 con use_lockfile), AWS CLI, GitHub + GitHub Actions (autenticación OIDC, sin llaves guardadas), tflint, checkov, gitleaks, LocalStack (Docker). Entorno: Windows + PowerShell, proyecto en D:\Ciclo 10\Servicios Cloud\Proyecto-Terraform.

## Estructura
modules/network, modules/compute, modules/firewall, modules/monitoring
sucursales/ (sucursales.yaml + main.tf con for_each)
bootstrap/ (bucket S3 del state, se aplica una sola vez)
.github/workflows/ (plan.yml, apply.yml, drift.yml)
docs/ (diagrama y guion de sustentación)

## Fases
0. Preparación de cuenta y herramientas: HECHA (verificar con aws sts get-caller-identity).
1. Módulo network: VPC, subredes públicas, IGW, rutas. Entradas: nombre, cidr, tags.
2. Módulos firewall y compute: security group (SSH restringido a mi IP) y 2 EC2 por sucursal.
3. Módulo monitoring: alarma de CPU por VM y tópico SNS con mi correo.
4. Multi-sucursal y state remoto: for_each sobre sucursales.yaml, bootstrap del bucket S3 (versionado y cifrado), backend con lock. Justificar state por sucursal vs por grupo.
5. Secretos: SSM Parameter Store + gitleaks como pre-commit.
6. Pipeline GitHub Actions: fmt, validate, tflint, checkov, plan comentado en el PR, aprobación obligatoria por environment, apply al merge, OIDC.
7. Drift: workflow nocturno con plan -detailed-exitcode que abre un issue. Demo: cambio manual de un security group en la consola, detección y corrección (revertir o codificar por PR).
8. Escala y sustentación: 50 sucursales en LocalStack, módulo/plan de GCP, diagrama y guion de 3 a 5 minutos (tabla decisión, herramienta, por qué).

## Estado actual
- Fases 0 y 1 hechas (network probado en AWS real con pruebas/network: 8 recursos, apply + destroy OK, 2026-10-04).
- Fase actual: 2 (código de firewall y compute + pruebas/fase2 escritos; pendiente plan/apply del usuario).
- Flujo de prueba: yo corro init/fmt/validate/plan -out=tfplan; el usuario corre `terraform apply tfplan` y `terraform destroy` en su PowerShell. Capturas en docs/evidencias/faseN/.
- Decisiones tomadas:
  - firewall: reglas como recursos separados (aws_vpc_security_group_*_rule) para que el drift se vea por regla. SSH solo desde cidrs_ssh (se rechaza 0.0.0.0/0); salida solo 80/443.
  - compute: AL2023 vía parámetro público SSM, ignore_changes=[ami] (evita reemplazos/falso drift), IMDSv2 obligatorio, disco gp3 8 GB cifrado, validación t3.micro/t2.micro y máx 2 VMs. VMs repartidas por subred (i % n) = una por AZ.
  - IP del usuario y ruta de llave SSH en terraform.tfvars (no versionado); solo se versiona *.tfvars.example.
  - network: subredes calculadas con cidrsubnet desde un solo CIDR por sucursal (/16 → /24), una por AZ, 2 por defecto (una por VM).
  - network: una sola tabla de rutas pública compartida; sin NAT (costo).
  - network: aws_default_security_group sin reglas (buena práctica; lo exige checkov).
  - Tags: el módulo recibe `tags` y añade solo `Name`.
  - .gitignore excluye state, *.tfvars (salvo *.tfvars.example), .aws/, *.csv, *.pem.

## Mantenimiento de este archivo
Al terminar cada fase, actualiza la sección "Estado actual" (fase completada, decisiones y su justificación, problemas encontrados y comandos útiles). Mantén este archivo corto y claro.
