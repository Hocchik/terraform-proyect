# `sucursales`: todas las sucursales con un solo código

`sucursales.yaml` es el catálogo de sucursales. `main.tf` recorre ese catálogo con `for_each` y crea, por cada sucursal, red, firewall, 2 VMs y monitoreo, usando los 4 módulos. **Agregar una sucursal = agregar 3 líneas al YAML** y abrir un PR.

## State: uno por grupo

Cada sucursal pertenece a un **grupo**, y cada grupo es un **workspace** de Terraform con su propio state en S3:

```
s3://<bucket>/grupos/piloto/sucursales.tfstate
s3://<bucket>/grupos/norte/sucursales.tfstate
...
```

| Opción | Ventaja | Problema |
|---|---|---|
| 1 state para las 50 | Lo más simple | Un error o un bloqueo afecta a las 50; plan lento (~1 000 recursos) |
| 1 state por sucursal | Aislamiento total | 50 init/plan en el pipeline; mucho que mantener |
| **1 state por grupo** ✅ | Un fallo solo afecta a su grupo; planes rápidos; grupos en paralelo | Hay que definir los grupos |

Que el grupo sea el workspace evita un error peligroso: aplicar las sucursales de un grupo sobre el state de otro, lo que borraría las sucursales de ese otro grupo. Si el workspace no coincide con ningún grupo del YAML (por ejemplo `default`), el plan falla con un mensaje claro. Por la misma razón, `terraform validate` también necesita el grupo, por ejemplo con `$env:TF_WORKSPACE = "piloto"`, que es como lo hará el pipeline.

## Uso (PowerShell, en esta carpeta)

```powershell
terraform init
terraform workspace select -or-create piloto
terraform plan -out=tfplan
terraform apply tfplan
```

Los valores comunes (`cidrs_ssh`, `clave_publica_ssh` y `correo`) van en `terraform.tfvars`, que **no se versiona**. Usa `terraform.tfvars.example` como modelo.

## Costo (grupo piloto, 2 sucursales en AWS real)

4 VMs t3.micro y 4 IPs públicas suman unos **$0.06 por hora**. Las 4 alarmas entran en la capa gratuita (10). Haz `terraform destroy` al terminar. Las 50 sucursales se demuestran en LocalStack (Fase 8).
