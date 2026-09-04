output "parameter_arns" {
  description = "ARNs only; secret values are never exposed."
  value = merge(
    { for key, parameter in aws_ssm_parameter.generated : key => parameter.arn },
    { for key, parameter in aws_ssm_parameter.encrypted : key => parameter.arn },
  )
}

output "parameter_names" {
  description = "SSM names only; secret values are never exposed."
  value = merge(
    { for key, parameter in aws_ssm_parameter.generated : key => parameter.name },
    { for key, parameter in aws_ssm_parameter.encrypted : key => parameter.name },
  )
}
