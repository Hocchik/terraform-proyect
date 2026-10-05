# Módulo `compute`

Crea las VMs EC2 de una sucursal (2 por defecto), repartidas entre las subredes para que cada una quede en una zona de disponibilidad distinta.

- AMI: Amazon Linux 2023 más reciente, obtenida del parámetro público de SSM.
- Solo `t3.micro` o `t2.micro` (la validación rechaza otros tipos).
- IMDSv2 obligatorio y disco raíz gp3 de 8 GB cifrado.
- `ignore_changes = [ami]` para que una AMI nueva no fuerce el reemplazo de las VMs.

## Uso

```hcl
module "compute" {
  source = "../modules/compute"

  nombre             = "lima-centro"
  subredes_ids       = module.network.subredes_publicas_ids
  security_group_ids = [module.firewall.security_group_id]
  key_name           = "iac-sucursales" # opcional
  tags               = local.tags
}
```

## Entradas

| Variable | Tipo | Por defecto | Descripción |
|---|---|---|---|
| `nombre` | string | (obligatoria) | Nombre de la sucursal |
| `subredes_ids` | list(string) | (obligatoria) | Subredes donde se reparten las VMs |
| `security_group_ids` | list(string) | (obligatoria) | Security groups de las VMs |
| `cantidad_vms` | number | `2` | De 1 a 2 |
| `tipo_instancia` | string | `t3.micro` | `t3.micro` o `t2.micro` |
| `key_name` | string | `null` | Key pair para SSH |
| `tags` | map(string) | `{}` | Tags comunes |

## Salidas

`instancias_ids`, `ips_publicas`, `ips_privadas`.

## Costo

Por cada VM, aproximadamente: t3.micro a $0.0104 por hora y su IP pública a $0.005 por hora, más el disco (dentro de los 30 GB gratuitos). Ambas VMs juntas cuestan unos **$0.03 por hora**, que se descuentan de los créditos. Haz `destroy` al terminar.
