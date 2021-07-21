output "external_ip_address_app" {
  value = module.app.external_ip_address_app
}
output "external_ip_address_db" {
  value = module.db.external_ip_address_db
}
// Задание со * для дз `terraform-1`
//output "external_id_address_load_balancer" {
//  value = yandex_lb_network_load_balancer.reddit_lb.listener.*.external_address_spec[0].*.address
//}
