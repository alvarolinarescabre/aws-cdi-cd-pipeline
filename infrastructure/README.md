# Infrastructure

Esta carpeta contiene plantillas de CloudFormation y scripts simples para desplegar la app Flask en ECS Fargate con ECR y CI/CD usando CodePipeline + CodeBuild.

## Estructura

- infrastructure/cloudformation/stack.yml: crea VPC, subredes, cluster ECS, servicio Fargate, rol de ejecución y repositorio ECR.
- infrastructure/cloudformation/pipeline.yml: crea CodeBuild, CodePipeline y el rol necesario para construir y publicar imágenes desde GitHub.
- infrastructure/scripts/deploy-stack.sh: helper para desplegar la pila base.

## Despliegue simple paso a paso

### 1) Crear la infraestructura base (ECR + ECS)

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/stack.yml \
  --stack-name app-demo-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### 2) Construir y subir la imagen inicial a ECR

```bash
aws ecr describe-repositories --repository-names api-repo --region us-east-1 || aws ecr create-repository --repository-name api-repo --region us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_URI="$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/api-repo"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$REPO_URI"
docker build -t "$REPO_URI:latest" -f apps/api/Dockerfile apps/api
docker push "$REPO_URI:latest"
```

### 3) Actualizar la pila para usar la imagen subida

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/stack.yml \
  --stack-name app-demo-stack \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ContainerImage="$REPO_URI:latest" \
  --region us-east-1
```

### 4) Crear el pipeline de CI/CD

Antes de ejecutar esta plantilla debes tener un secreto en Secrets Manager con el token de GitHub:

```bash
aws secretsmanager create-secret \
  --name github-token \
  --secret-string '{"token":"TU_TOKEN_DE_GITHUB"}' \
  --region us-east-1
```

Luego despliega la plantilla de pipeline:

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/pipeline.yml \
  --stack-name app-demo-pipeline \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOwner=TU_USUARIO_GITHUB \
    GitHubRepo=TU_REPO_GITHUB \
    GitHubBranch=main \
    GitHubOAuthTokenSecretName=github-token \
    ECRRepositoryName=api-repo \
    ECSClusterName=app-demo-cluster \
    ECSServiceName=app-demo-service \
  --region us-east-1
```

> Importante: el valor de ECSClusterName y ECSServiceName debe coincidir con el nombre generado por la pila base. Si cambias el parámetro EnvironmentName o el nombre del stack, revisa los outputs.

## Validación

1. Abre CodePipeline y revisa que el pipeline complete la ejecución.
2. En ECS, revisa que el servicio quede en estado ACTIVE.
3. Abre la IP pública del servicio para ver la respuesta de la app.
