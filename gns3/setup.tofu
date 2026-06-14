# ---------------------------------------------------------------------------
# Example on how to get client credentials from incus using the incus provider
#
# 1. Bootstrap:
#    Create a client token on a first run (or fresh client) to authenticate
#    this client with the server. You must provide the incus token so that
#    the provider can receive the server generated client credentials and
#    store them in this project levels ./incus/.
#
# 2. Subsequent runs:
#    Once the credentials are stored in ./incus/ the provider configuration
#    will pick them up and authenticate using them. There is no need to
#    still provide the token. It is meant to expire and used only once.
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.12"

  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 1.1"
    }
  }
}


provider "incus" {

  # Will this just use the odin i know?
  remote {
    name = "odin"
  }
}
