<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [yandex_compute_instance.db](https://registry.terraform.io/providers/hashicorp/yandex/latest/docs/resources/compute_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_disc_image"></a> [db\_disc\_image](#input\_db\_disc\_image) | Disk image for reddit db | `string` | `"mongodb-base"` | no |
| <a name="input_public_key_path"></a> [public\_key\_path](#input\_public\_key\_path) | Path to the public key used for ssh access | `any` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnets for modules | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_ip_address_db"></a> [external\_ip\_address\_db](#output\_external\_ip\_address\_db) | n/a |
<!-- END_TF_DOCS -->
