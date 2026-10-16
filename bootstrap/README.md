# `bootstrap`: bucket del state remoto

Crea el bucket S3 donde Terraform guarda el state de todas las sucursales. Se aplica **una sola vez**.

| Protección | Para qué |
|---|---|
| Nombre con sufijo único (`bucket_prefix`) | Los nombres de bucket son globales; además el nombre no expone el ID de la cuenta |
| Versionado | Recuperar una versión anterior si el state se corrompe o se borra |
| Cifrado SSE-S3 (AES256) | El state puede tener datos sensibles; SSE-S3 es gratis (KMS propio cuesta $1/mes) |
| Bloqueo de acceso público | Nadie de fuera de la cuenta puede leerlo |
| Política "solo HTTPS" | Cifrado en tránsito |
| Ciclo de vida (versiones viejas a los 90 días) | Que el bucket no crezca sin límite |
| `prevent_destroy` | Un `terraform destroy` por error no borra el state de las 50 sucursales |

El **bloqueo** (lock) no necesita DynamoDB. Desde Terraform 1.10, `use_lockfile = true` crea un archivo `.tflock` en el mismo bucket mientras dura un `plan` o un `apply`.

## Pasos (una sola vez)

1. **Crear el bucket con state local:** `terraform init`, luego `terraform plan -out=tfplan` y `terraform apply tfplan`. Anota el output `bucket_state`.
2. **Mover el state del bootstrap al bucket.** Pon el nombre del bucket en `backend.tf` y ejecuta `terraform init -migrate-state` (responde `yes`). Así el bucket guarda su propio state y no depende de un archivo en tu PC.
3. Pon el mismo nombre en `sucursales/backend.tf`.

## Borrarlo al final del curso

Quita `prevent_destroy` y agrega `force_destroy = true` al bucket. Luego corre `terraform apply` y, después, `terraform destroy`. Antes, todos los grupos de `sucursales/` deben estar destruidos.

## Costo

≈ $0. El state pesa unos pocos KB; la capa gratuita de S3 incluye 5 GB y miles de peticiones.
