resource "aws_instance" "web" {
  count = 2
  ami = "ami-0ae8f15ae66fe8cda" # Exemplo de AMI, substitua conforme necessário
  instance_type = "t2.micro"
  subnet_id = element(var.subnet_ids, count.index)
  vpc_security_group_ids = [var.security_group_id]
}

resource "aws_launch_configuration" "example" {
  name          = "example-launch-configuration-unique"
  image_id      = "ami-0ae8f15ae66fe8cda"
  instance_type = "t2.micro"
  security_groups = [var.security_group_id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = ["subnet-0f0914a6453a66430", "subnet-097610122c23df076"]
  launch_configuration = aws_launch_configuration.example.id
  tag {
    key                 = "Name"
    value               = "example-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}