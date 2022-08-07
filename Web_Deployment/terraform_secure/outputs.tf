/*The outputs tf file, this will return specific info to us upon deployment.
This info will just make it easier to interact with what we've deployed*/

#Output a url that will resolve to the site hosted on one of the instances.
output "URL" {
  description = "A link/URL to access the site."
  value       = "Site link: ${var.alb_domain}"
}

#Give additional instructions on how to access the instances directly.
output "Message" {
  value = "If there are any issues with the site, connect to the instances via aws session manager as port 22 is blocked."
}