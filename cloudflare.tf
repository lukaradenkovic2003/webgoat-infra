# 1. Generisanje tajnog tokena za autorizaciju saobraćaja sa Cloudflare-a ka ALB-u
resource "random_password" "cloudflare_alb_secret" {
  length  = 32
  special = false
}

# 2. CNAME rekord za Root domen (Cloudflare radi automatski CNAME Flattening za @)
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = var.alb_dns_name # DNS ime AWS ALB-a (prenosi se iz varijable ili EKS Ingress-a)
  type    = "CNAME"
  ttl     = 1
  proxied = true # Omogućava WAF, DDoS i HTTPS proxy
}

# 3. CNAME rekord za www poddomen
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  content = var.domain_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

# 4. Transform Rule - Ubacuje tajni X-Cloudflare-Secret header
resource "cloudflare_ruleset" "add_custom_header" {
  zone_id     = var.cloudflare_zone_id
  name        = "Add Custom Header for ALB"
  description = "Ubacuje tajni header u zahteve kako bi AWS ALB prihvatao samo Cloudflare saobraćaj"
  kind        = "zone"
  phase       = "http_request_late_transform"

  rules {
    action = "rewrite"
    action_parameters {
      headers {
        name  = "X-Cloudflare-Secret"
        value = random_password.cloudflare_alb_secret.result
      }
    }
    expression  = "true"
    description = "Inject X-Cloudflare-Secret Header"
    enabled     = true
  }
}

# 5. WAF Custom Rule - Geo-blocking pravilo
resource "cloudflare_ruleset" "geo_blocking" {
  zone_id     = var.cloudflare_zone_id
  name        = "Geo-blocking rules"
  description = "Blokira pristup iz visoko-rizičnih geografskih regiona"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "block"
    expression  = "(ip.src.country in {\"XK\" \"RU\" \"CN\" \"IR\"})"
    description = "Block high-risk countries"
    enabled     = true
  }
}