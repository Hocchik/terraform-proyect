# Módulo `monitoring`

Vigila las VMs de una sucursal:

- **Tópico SNS** `<nombre>-alertas`, con una suscripción por correo si se indica `correo`.
- **Una alarma de CloudWatch por VM** (`<nombre>-vm-N-cpu-alta`). Salta si la CPU promedio supera `umbral_cpu` (80 % por defecto) durante 10 minutos (2 periodos de 5 min). Avisa al entrar en ALARM y al volver a OK.

Cada sucursal tiene su propio tópico para que quede completa en su propio state, sin depender de recursos compartidos. El correo no se versiona: viene de un `.tfvars` ignorado por git.

El tópico no va cifrado con KMS. CloudWatch no puede publicar en un tópico cifrado con la llave administrada `aws/sns`, y una llave propia cuesta $1 al mes. Las alertas no llevan datos sensibles, así que se omite la regla `CKV_AWS_26` de checkov, con la justificación anotada en el código.

## Uso

```hcl
module "monitoring" {
  source = "../modules/monitoring"

  nombre         = "lima-centro"
  instancias_ids = module.compute.instancias_ids
  correo         = var.correo # opcional; null = sin suscriptor
  tags           = local.tags
}
```

## Entradas

| Variable | Tipo | Por defecto | Descripción |
|---|---|---|---|
| `nombre` | string | (obligatoria) | Nombre de la sucursal |
| `instancias_ids` | list(string) | (obligatoria) | VMs a vigilar (de `compute`) |
| `correo` | string | `null` | Correo que recibe las alertas |
| `umbral_cpu` | number | `80` | % de CPU que dispara la alarma |
| `tags` | map(string) | `{}` | Tags comunes |

## Salidas

`sns_topic_arn`, `alarmas`.

## Probar sin estresar la CPU

Puedes forzar el estado de una alarma. Llega el correo de ALARM y, en la siguiente evaluación (unos 5 min), el de OK:

```powershell
aws cloudwatch set-alarm-state --alarm-name lima-centro-vm-1-cpu-alta --state-value ALARM --state-reason "Prueba manual"
```

Recuerda que AWS manda primero un correo de confirmación de la suscripción. Hasta que hagas clic en *Confirm subscription* no llega ninguna alerta.

## Costo

$0 dentro de la capa gratuita: 10 alarmas al mes (luego $0.10 por alarma al mes), 1 000 correos de SNS al mes y monitoreo básico de EC2. Con 2 VMs por sucursal, la capa gratuita alcanza para 5 sucursales reales. Las 50 sucursales se demuestran en LocalStack.
