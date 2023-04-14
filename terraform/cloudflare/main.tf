terraform {

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.2"
    }
  }
}

data "sops_file" "cloudflare_secrets" {
  source_file = "secret.sops.yaml"
}

provider "cloudflare" {
  email   = data.sops_file.cloudflare_secrets.data["cloudflare_email"]
  api_key = data.sops_file.cloudflare_secrets.data["cloudflare_apikey"]
}

data "cloudflare_zones" "domain" {
  filter {
    name = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  }
}

resource "cloudflare_zone_settings_override" "cloudflare_settings" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  settings {
    ssl                      = "strict"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    universal_ssl            = "on"
    browser_check            = "on"
    challenge_ttl            = 1800
    privacy_pass             = "on"
    security_level           = "medium"
    brotli                   = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    rocket_loader       = "on"
    always_online       = "off"
    development_mode    = "off"
    http3               = "on"
    zero_rtt            = "on"
    ipv6                = "on"
    websockets          = "on"
    opportunistic_onion = "on"
    pseudo_ipv4         = "off"
    ip_geolocation      = "on"
    email_obfuscation   = "on"
    server_side_exclude = "on"
    hotlink_protection  = "off"
    security_header {
      enabled = false
    }
  }
}

data "http" "ipv4" {
  url = "http://ipv4.icanhazip.com"
}

resource "cloudflare_record" "ipv4" {
  name    = "ipv4"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "root" {
  name    = data.sops_file.cloudflare_secrets.data["cloudflare_domain"]
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${data.sops_file.cloudflare_secrets.data["cloudflare_domain"]}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "ses_dkim_1" {
  name    = "yvuyrpzqcwyvfthavtoanh7jjd4uas6k._domainkey.phekno.io"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "yvuyrpzqcwyvfthavtoanh7jjd4uas6k.dkim.amazonses.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "ses_dkim_2" {
  name    = "qg2wghyksntqg5roetppszp5fg4cdclx._domainkey.phekno.io"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "qg2wghyksntqg5roetppszp5fg4cdclx.dkim.amazonses.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "ses_dkim_3" {
  name    = "ig7l2ajxur4anp2useowkatq3ppa6lbv._domainkey.phekno.io"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ig7l2ajxur4anp2useowkatq3ppa6lbv.dkim.amazonses.com"
  proxied = false
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "ses_mailfrom_mx" {
  name     = "mail.phekno.io"
  zone_id  = lookup(data.cloudflare_zones.domain.zones[0], "id")
  type     = "MX"
  priority = 10
  value    = "feedback-smtp.us-east-1.amazonses.com"
  proxied  = false
  ttl      = 1
}

resource "cloudflare_record" "ses_mailfrom_spf" {
  name    = "mail.phekno.io"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "v=spf1 include:amazonses.com ~all"
  proxied = false
  type    = "TXT"
  ttl     = 1
}
