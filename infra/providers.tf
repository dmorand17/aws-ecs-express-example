provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        managed-by = "terraform"
        project    = "ecs-express-fastapi"
      },
      var.additional_tags
    )
  }
}
