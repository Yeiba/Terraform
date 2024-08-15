## Requirements


| Name                                                                      | Version   |
| ------------------------------------------------------------------------- | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3.0  |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | ~> 4.37.0 |

## Providers


| Name                                              | Version   |
| ------------------------------------------------- | --------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.37.0 |

## Modules

No modules.

## Resources


| Name                                                                                                                                                    | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip)                                                         | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)                                         | resource |
| [aws_route.private_routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route)                                           | resource |
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table)                                         | resource |
| [aws_route_table_association.assoc_private_routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |

## Inputs


| Name                                                                                                    | Description               | Type          | Default    | Required |
| ------------------------------------------------------------------------------------------------------- | ------------------------- | ------------- | ---------- | :------: |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region)                                      | AWS infrastructure region | `string`      | `null`     |    no    |
| <a name="input_connectivity_type"></a> [connectivity\_type](#input\_connectivity\_type)                 | connectivity\_type        | `string`      | `"public"` |    no    |
| <a name="input_nat_private_subnet_id"></a> [nat\_private\_subnet\_id](#input\_nat\_private\_subnet\_id) | nat\_private\_subnet\_id  | `string`      | `null`     |    no    |
| <a name="input_nat_public_subnet_id"></a> [nat\_public\_subnet\_id](#input\_nat\_public\_subnet\_id)    | nat\_public\_subnet\_id   | `string`      | `null`     |    no    |
| <a name="input_prefix"></a> [prefix](#input\_prefix)                                                    | Resource name prefix      | `string`      | `null`     |    no    |
| <a name="input_tags"></a> [tags](#input\_tags)                                                          | Tag map for the resource  | `map(string)` | `{}`       |    no    |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id)                                                  | AWS VPC id                | `string`      | `null`     |    no    |

## Outputs


| Name                                                                                                                     | Description            |
| ------------------------------------------------------------------------------------------------------------------------ | ---------------------- |
| <a name="output_eip_allocation_id"></a> [eip\_allocation\_id](#output\_eip\_allocation\_id)                              | allocation\_id         |
| <a name="output_eip_association_id"></a> [eip\_association\_id](#output\_eip\_association\_id)                           | association\_id        |
| <a name="output_eip_domain"></a> [eip\_domain](#output\_eip\_domain)                                                     | domain                 |
| <a name="output_eip_private_dns"></a> [eip\_private\_dns](#output\_eip\_private\_dns)                                    | eip\_private\_dns      |
| <a name="output_eip_public_dns"></a> [eip\_public\_dns](#output\_eip\_public\_dns)                                       | eip\_public\_dns       |
| <a name="output_natgw_allocation_id"></a> [natgw\_allocation\_id](#output\_natgw\_allocation\_id)                        | allocation\_id         |
| <a name="output_natgw_connectivity_type"></a> [natgw\_connectivity\_type](#output\_natgw\_connectivity\_type)            | connectivity\_type     |
| <a name="output_natgw_network_interface_id"></a> [natgw\_network\_interface\_id](#output\_natgw\_network\_interface\_id) | network\_interface\_id |
| <a name="output_natgw_private_ip"></a> [natgw\_private\_ip](#output\_natgw\_private\_ip)                                 | private\_ip            |
| <a name="output_natgw_public_ip"></a> [natgw\_public\_ip](#output\_natgw\_public\_ip)                                    | private\_ip            |
| <a name="output_natgw_subnet_id"></a> [natgw\_subnet\_id](#output\_natgw\_subnet\_id)                                    | subnet\_id             |
| <a name="output_rt_arn"></a> [rt\_arn](#output\_rt\_arn)                                                                 | id                     |
| <a name="output_rt_id"></a> [rt\_id](#output\_rt\_id)                                                                    | id                     |
