output "vpc_id" {
  value = aws_vpc.demovpc.id
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.rds_subnetgroup.*.name
}

output "rds_db_subnet_group" {
  value = aws_db_subnet_group.rds_subnetgroup.*.id
}

output "rds_sg" {
  value = aws_security_group.rds_sg.id
}

output "frontend_app_sg" {
  value = aws_security_group.frontend_app_sg.id
}

output "backend_app_sg" {
  value = aws_security_group.backend_app_sg.id
}

output "bastion_sg" {
  value = aws_security_group.bastion_sg.id
}

output "lb_sg" {
  value = aws_security_group.lb_sg.id
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "private_subnets" {
  value = aws_subnet.private_subnets.*.id
}

output "private_subnets_db" {
  value = aws_subnet.private_subnets_db.*.id
}
