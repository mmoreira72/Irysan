
resource "aws_cloudwatch_dashboard" "eks_dashboard" {
  dashboard_name = var.dashboard_name

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ContainerInsights", "cpu_utilization", "ClusterName", var.cluster_name ]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "EKS CPU Utilization"
        }
      },
      {
        type = "metric",
        x    = 12,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ContainerInsights", "memory_utilization", "ClusterName", var.cluster_name ]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "EKS Memory Utilization"
        }
      }
    ]
  })
}
