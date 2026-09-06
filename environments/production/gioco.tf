locals {
  gioco_generated_parameters = {
    postgres_password = {
      name        = "/gioco/production/postgres/password"
      description = "PostgreSQL password for the Frostwood authoritative game server"
      length      = 48
      special     = false
      version     = 1
      tags = {
        Workload = "gioco"
      }
    }
  }
}
