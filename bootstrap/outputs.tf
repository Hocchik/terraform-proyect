output "bucket_state" {
  description = "Nombre del bucket del state. Va en el bloque backend de sucursales/ y de este mismo bootstrap."
  value       = aws_s3_bucket.state.id
}
