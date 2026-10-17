# Módulo monitoring: un tópico SNS por sucursal y una alarma de CPU por VM.
# Usa el monitoreo básico de EC2 (métricas cada 5 min, gratis); el detallado cobra.

resource "aws_sns_topic" "alertas" {
  #checkov:skip=CKV_AWS_26:Con la llave administrada aws/sns, CloudWatch no puede publicar en el tópico; una llave KMS propia cuesta $1/mes. Las alertas no llevan datos sensibles.
  name = "${var.nombre}-alertas"

  tags = merge(var.tags, { Name = "${var.nombre}-alertas" })
}

# Suscripción por correo. AWS envía un correo de confirmación: hasta hacer clic en
# "Confirm subscription" no llega ninguna alerta. Sin correo (ej. LocalStack) no se crea.
resource "aws_sns_topic_subscription" "correo" {
  count = var.correo == null ? 0 : 1

  topic_arn = aws_sns_topic.alertas.arn
  protocol  = "email"
  endpoint  = var.correo
}

# Una alarma por VM: CPU promedio > umbral durante 2 periodos seguidos de 5 min (10 min).
# Avisa al entrar en ALARM y también cuando vuelve a OK.
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = length(var.instancias_ids)

  alarm_name          = "${var.nombre}-vm-${count.index + 1}-cpu-alta"
  alarm_description   = "CPU de ${var.nombre}-vm-${count.index + 1} sobre ${var.umbral_cpu}% durante 10 minutos"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  dimensions          = { InstanceId = var.instancias_ids[count.index] }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.umbral_cpu

  alarm_actions = [aws_sns_topic.alertas.arn]
  ok_actions    = [aws_sns_topic.alertas.arn]

  tags = merge(var.tags, { Name = "${var.nombre}-vm-${count.index + 1}-cpu-alta" })
}
