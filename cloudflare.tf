
# Root DNS A rekord (@ / webgoat-devsecops.xyz)
resource "cloudflare_record" "root_a" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content   = "192.0.2.1" # Privremena vrednost dok ne povežeš Load Balancer / Ingress
  type    = "A"
  ttl     = 1
  proxied = true
}

# CNAME rekord za www poddomen (www.webgoat-devsecops.xyz)
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  content   = var.domain_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

# WAF Geo-blocking pravilo — NACRT, dovršava se kad ALB postoji
# Za sada blokira (primer) saobraćaj iz određenih zemalja - prilagodi listu po potrebi

resource "cloudflare_ruleset" "geo_blocking" {
  zone_id     = var.cloudflare_zone_id
  name        = "Geo-blocking rules"
  description = "Blokira/dozvoljava pristup po geografskom regionu"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "block"
    expression  = "(ip.geoip.country in {\"KP\" \"RU\"})"
    description = "Block traffic from specific countries"
    enabled     = true
  }
}

