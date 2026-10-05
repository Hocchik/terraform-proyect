# Módulo compute: VMs EC2 de la sucursal, repartidas entre las subredes (una por zona).

# AMI más reciente de Amazon Linux 2023, publicada por AWS en un parámetro público de SSM.
# Evita escribir un ID de AMI fijo (cambia por región y queda viejo).
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "vm" {
  count = var.cantidad_vms

  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.tipo_instancia
  subnet_id              = var.subredes_ids[count.index % length(var.subredes_ids)]
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name

  # IMDSv2 obligatorio: protege las credenciales del metadata service (exigido por checkov, costo $0).
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  # Disco cifrado con la llave administrada por AWS (gratis). 8 GB entra en la capa gratuita.
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
    tags        = merge(var.tags, { Name = "${var.nombre}-vm-${count.index + 1}-disco" })
  }

  tags = merge(var.tags, { Name = "${var.nombre}-vm-${count.index + 1}" })

  lifecycle {
    # Cuando AWS publica una AMI nueva, el plan querría REEMPLAZAR las VMs.
    # Lo ignoramos para que eso no aparezca como cambio (ni como falso drift).
    ignore_changes = [ami]
  }
}
