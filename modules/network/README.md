# Módulo `network`

Crea la red de una sucursal: VPC, subredes públicas (una por zona de disponibilidad), Internet Gateway y una tabla de rutas con salida a Internet. También deja sin reglas el security group por defecto de la VPC.

**Sin NAT Gateway** para mantener el costo en $0: las VMs usan IP pública y salen a Internet por el IGW.

## Uso

```hcl
module "network" {
  source = "../modules/network"

  nombre = "lima-centro"
  cidr   = "10.1.0.0/16"
  tags = {
    Proyecto = "iac-sucursales"
    Sucursal = "lima-centro"
    Entorno  = "practica"
  }
}
```

Con `cidr = "10.1.0.0/16"` y 2 subredes se crean `10.1.0.0/24` (us-east-2a) y `10.1.1.0/24` (us-east-2b).

## Entradas

| Variable | Tipo | Por defecto | Descripción |
|---|---|---|---|
| `nombre` | string | (obligatoria) | Nombre de la sucursal (minúsculas, números y guiones) |
| `cidr` | string | (obligatoria) | CIDR de la VPC, se recomienda un /16 distinto por sucursal |
| `cantidad_subredes` | number | `2` | Subredes públicas, de 1 a 3 |
| `tags` | map(string) | `{}` | Tags comunes |

## Salidas

`vpc_id`, `vpc_cidr`, `subredes_publicas_ids`, `zonas`, `internet_gateway_id`.

## Costo

VPC, subredes, IGW y tablas de rutas no cobran. Lo que sí cobra es cada **IP pública IPv4** (unos $0.005 por hora) que reciban las VMs del módulo compute.
