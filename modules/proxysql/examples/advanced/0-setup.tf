terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4"
    }
  }
}

# you can pass helm provider config like `export KUBE_CONFIG_PATH=/path/to/k8s.kubeconfig`
provider "helm" {}


# make sure you have mysql server running at mysql.localhost endpoint, you can use this helm command to setup one `helm diff upgrade --install -n localhost mysql  bitnami/mysql --set auth.rootPassword=root`
