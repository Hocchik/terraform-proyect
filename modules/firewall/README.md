# Módulo `firewall`

Crea el security group de las VMs de una sucursal:

- **Entrada:** solo SSH (22/tcp) desde los CIDR de `cidrs_ssh`. La validación rechaza `0.0.0.0/0`.
- **Salida:** solo HTTP (80) y HTTPS (443), para actualizar paquetes. El DNS de AWS no pasa por el security group.

Cada regla es un recurso separado (`aws_vpc_security_group_ingress_rule` / `egress_rule`), lo que hace que el drift en una regla se vea claro en el plan.

## Uso

```hcl
module "firewall" {
  source = "../modules/firewall"

  nombre    = "lima-centro"
  vpc_id    = module.network.vpc_id
  cidrs_ssh = ["190.12.34.56/32"] # tu IP pública; viene de un .tfvars NO versionado
  tags      = local.tags
}
```

## Entradas

| Variable | Tipo | Descripción |
|---|---|---|
| `nombre` | string | Nombre de la sucursal |
| `vpc_id` | string | VPC donde se crea (de `network`) |
| `cidrs_ssh` | list(string) | CIDR autorizados para SSH (nunca `0.0.0.0/0`) |
| `tags` | map(string) | Tags comunes |

## Salidas

`security_group_id`, `security_group_nombre`.

## Costo

$0. Los security groups no cobran.
