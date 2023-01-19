resource "aws_secretsmanager_secret" "redshift_connection" {
  description = "Redshift connectection"
  name        = "redshift_secret_${random_string.unique_suffix.result}"
}

resource "aws_secretsmanager_secret_version" "redshift_connection" {
  secret_id = aws_secretsmanager_secret.redshift_connection.id
  secret_string = jsonencode({
    username            = aws_redshift_cluster.mycluster.master_username
    password            = aws_redshift_cluster.mycluster.master_password
    engine              = "redshift"
    host                = aws_redshift_cluster.mycluster.endpoint
    port                = "5439"
    dbClusterIdentifier = aws_redshift_cluster.mycluster.cluster_identifier
  })

  depends_on = [
    aws_redshift_cluster.mycluster
  ]
}