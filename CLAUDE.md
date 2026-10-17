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
Terraform (>= 1.10, backend S3 con use_lockfile), AWS CLI, GitHub + GitHub Actions (autenticación OIDC, sin llaves guardadas), tflint, checkov, gitleaks, LocalStack (Docker). Entorno: Windows + PowerShell. PC 1: D:\Ciclo 10\Servicios Cloud\Proyecto-Terraform; laptop 2: C:\Ciclo 10\Servicios Cloud\Terraform-proyect\terraform-proyect.

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
- Fase 2 hecha (2026-10-16): pruebas/fase2 = 15 recursos, apply + SSH desde la IP del usuario + salida web (dnf) + destroy OK.
- Fase 3 hecha (2026-10-16): pruebas/fase3 = 19 recursos, suscripción confirmada, alarma forzada a ALARM con `aws cloudwatch set-alarm-state` (llegó correo) y volvió sola a OK con datos reales (CPU 0.2 %), destroy OK.
- Fase 4 hecha (2026-10-16): bootstrap aplicado (bucket `iac-sucursales-tfstate-20261016220316735500000001`, PERMANENTE, no se destruye) y su state migrado al propio bucket (`bootstrap/terraform.tfstate`). Grupo piloto (lima-centro 10.1.0.0/16 + arequipa 10.2.0.0/16) = 37 recursos, apply + destroy OK; state en `grupos/piloto/sucursales.tfstate`.
- Fase actual: 5 (secretos). Esperando confirmación del usuario para empezar.
- Repo: https://github.com/Hocchik/terraform-proyect. Fases 3 y 4 (ec8b3c5, f528874) entran a main por PR desde `claude/continuar-proyecto-6b1ab6`. Orden acordado: PR → rama `laboratorio-monitoreo` → rama `fase-5-secretos`.
- Laboratorio de monitoreo (aparte de las fases; guía "Monitoreo en la nube y gestión de métricas en TSDB", 40 min, informe 3-5 págs): carpeta `laboratorio-monitoreo/` con state propio (`laboratorio/monitoreo.tfstate`), reutiliza los 4 módulos con 1 sucursal `lab-monitoreo` de 2 VMs (vm-1 recibe la falla, vm-2 = control). CloudWatch en vez de Prometheus (la guía admite TSDB equivalente): CloudWatch Agent (CPU activa/steal y memoria a 1 min; máx 10 métricas personalizadas gratis), EBS para I/O, sonda de latencia por StatsD, dashboard, alarmas CPU + latencia. Fallas a analizar: CPU y memoria (`incidente.sh cpu|memoria|disco` con stress-ng). Cambios a módulos solo opcionales/compatibles (compute: user_data, perfil IAM, `cpu_credits = "standard"`; monitoring: output ARN de alarmas); el plan de sucursales debe seguir en 37.
- Pendiente: capturas 04-rutas, 05-gateways, 06-destroy de fase1 sin versionar porque muestran el ID de cuenta; taparlo antes de subirlas. Fase2: faltan 01-apply, 02-instancias, 03-sg-reglas (opcionales).
- Capturas con ID de cuenta o correo: se tapan con un script de System.Drawing (rectángulos grises) y se verifican viéndolas antes de copiarlas a docs/evidencias. Los correos de AWS traen el ID en "AWS Account" y en los ARN.
- Laptop 2 (2026-10-16): instalados terraform 1.16.5, AWS CLI 2.38.1, tflint 0.64.0, gitleaks 8.30.1 (winget) y checkov 3.3.29 (pip). Access key propia de la laptop (`laptop-2`) con `aws configure` hecho por el usuario; STS responde admin-iac. Si un comando recién instalado no se encuentra, abrir otra PowerShell (PATH).
- Flujo de prueba: yo corro init/fmt/validate/plan -out=tfplan; el usuario corre `terraform apply tfplan` y `terraform destroy` en su PowerShell. Capturas en docs/evidencias/faseN/.
  - Ojo: si la sesión corre en un worktree, el plan queda en `.claude\worktrees\<nombre>\pruebas\faseN`; darle al usuario el `cd` completo y los valores reales (IPs) en vez de placeholders como `<IP>`.
  - Llave SSH: `$HOME\.ssh\iac-sucursales(.pub)` (ed25519). Cada máquina tiene la suya: el key pair `iac-sucursales-<grupo>` usa la .pub del tfvars de quien aplica. Entrar: `ssh -i "$HOME\.ssh\iac-sucursales" ec2-user@<ip>`; IPs con `terraform output ips_publicas`.
- Decisiones tomadas:
  - firewall: reglas como recursos separados (aws_vpc_security_group_*_rule) para que el drift se vea por regla. SSH solo desde cidrs_ssh (se rechaza 0.0.0.0/0); salida solo 80/443.
  - compute: AL2023 vía parámetro público SSM, ignore_changes=[ami] (evita reemplazos/falso drift), IMDSv2 obligatorio, disco gp3 8 GB cifrado, validación t3.micro/t2.micro y máx 2 VMs. VMs repartidas por subred (i % n) = una por AZ.
  - monitoring: un tópico SNS por sucursal (la sucursal queda completa en su state, sin recursos compartidos) + una alarma CPU por VM (Average > 80 % en 2 periodos de 5 min, avisa en ALARM y en OK). Monitoreo básico (gratis). Tópico sin KMS: CloudWatch no publica en tópicos cifrados con aws/sns y una CMK cuesta $1/mes → `#checkov:skip=CKV_AWS_26` justificado. `correo` opcional (null = sin suscriptor, para LocalStack/CI). Capa gratuita: 10 alarmas = 5 sucursales reales.
  - El correo de SNS de AWS cae en "Correo no deseado" de Outlook; la suscripción no envía alertas hasta hacer clic en "Confirm subscription".
  - IP del usuario, ruta de llave SSH y correo en terraform.tfvars (no versionado); solo se versiona *.tfvars.example.
  - State: uno por GRUPO = workspace de Terraform (backend S3 con `workspace_key_prefix = "grupos"` y `use_lockfile`, sin DynamoDB). El grupo sale de `terraform.workspace`, así no se puede aplicar un grupo sobre el state de otro. Output `grupo` con precondition: falla si el workspace no es un grupo del YAML (incluido `default`), por eso `validate` también necesita `$env:TF_WORKSPACE = "<grupo>"`.
  - sucursales/: `sucursales.yaml` (lista nombre/grupo/cidr; nombre repetido = error) + for_each sobre los 4 módulos directamente (sin módulo "sucursal" envoltorio). Tag extra `Grupo`. Una llave SSH por grupo (`iac-sucursales-<grupo>`), pasada como contenido (`clave_publica_ssh`) para que funcione también en CI.
  - bootstrap: `bucket_prefix` (nombre único sin exponer el ID de cuenta), versionado, SSE-S3 (KMS cuesta), bloqueo público, política solo HTTPS, lifecycle de versiones viejas a 90 días, `prevent_destroy`. Skips de checkov justificados en el código (logs de acceso, replicación, KMS, notificaciones).
  - Comandos sucursales: `terraform init`, `terraform workspace select -or-create piloto`, `terraform plan -out=tfplan`.
  - network: subredes calculadas con cidrsubnet desde un solo CIDR por sucursal (/16 → /24), una por AZ, 2 por defecto (una por VM).
  - network: una sola tabla de rutas pública compartida; sin NAT (costo).
  - network: aws_default_security_group sin reglas (buena práctica; lo exige checkov).
  - Tags: el módulo recibe `tags` y añade solo `Name`.
  - .gitignore excluye state, *.tfvars (salvo *.tfvars.example), .aws/, *.csv, *.pem.

## Mantenimiento de este archivo
Al terminar cada fase, actualiza la sección "Estado actual" (fase completada, decisiones y su justificación, problemas encontrados y comandos útiles). Mantén este archivo corto y claro.
