output "sns_topic_arn" {
  description = "ARN del tópico SNS de alertas de la sucursal."
  value       = aws_sns_topic.alertas.arn
}

output "alarmas" {
  description = "Nombres de las alarmas de CPU (sirven para probarlas con 'aws cloudwatch set-alarm-state')."
  value       = aws_cloudwatch_metric_alarm.cpu[*].alarm_name
}
