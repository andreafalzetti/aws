output "parameter_names" {
  description = "Created parameter names; never contains secret values."
  value       = module.ssm_parameters.parameter_names
}
