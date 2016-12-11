# Prerequisites:
- AWS Cli configured with your credentials

# Usage:
- Go to tools directory `cd tools/`
- Generate Base AMI image `./pack-ami build -t base -p ../packer/`
- Generate ECS AMI image `./pack-ami build -t ecs -p ../packer/`
- Your new Base and ECS AMIs are available in your AWS account
- You can delete the Base AMI image
- Set the ECS AMI Permission to public
- Edit the `defaults/maint.tf` file and set the new ECS AMI ID corresponding to the zone where your AMI has been created
- Copy your ECS AMI to each zone available in `defaults/maint.tf` AND DO NOT FORGET TO MAKE THEM PUBLIC TOO.
