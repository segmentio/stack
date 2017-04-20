#cloud-config
bootcmd:
  - echo 'SERVER_ENVIRONMENT=${environment}' >> /etc/environment
  - echo 'SERVER_GROUP=${name}' >> /etc/environment
  - echo 'SERVER_REGION=${region}' >> /etc/environment

  - mkdir -p /etc/ecs
  - echo 'ECS_CLUSTER=${name}' >> /etc/ecs/ecs.config
  - echo 'ECS_ENGINE_AUTH_TYPE=${docker_auth_type}' >> /etc/ecs/ecs.config
  - >
    echo 'ECS_ENGINE_AUTH_DATA=${docker_auth_data}' >> /etc/ecs/ecs.config
