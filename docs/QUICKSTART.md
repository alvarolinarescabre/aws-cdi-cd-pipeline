# Quick Start — Referencia de comandos

Guía rápida para desplegar el pipeline completo desde cero.
Para entender la arquitectura ve a [docs/README.md](README.md).

---

## Variables de entorno (configura primero)

```bash
export AWS_DEFAULT_REGION=eu-west-1          # tu región
export STACK_NAME=app-demo-stack             # nombre del stack de infraestructura
export PIPELINE_STACK_NAME=app-demo-pipeline # nombre del stack del pipeline
export GITHUB_OWNER=tu-usuario              # usuario u organización GitHub
export GITHUB_REPO=aws-cdi-cd-pipeline      # nombre del repositorio GitHub
export GITHUB_BRANCH=main
```

---

## 1. Token de GitHub → Secrets Manager

```bash
# Crea un token en GitHub con permisos: repo + admin:repo_hook
aws secretsmanager create-secret \
  --name github-token \
  --secret-string '{"token":"ghp_TU_TOKEN_AQUI"}' \
  --region $AWS_DEFAULT_REGION
```

---

## 2. Infraestructura base

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/stack.yml \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_DEFAULT_REGION
```

---

## 3. Leer outputs del stack base

```bash
export ECR_REPO_NAME=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='ECRRepositoryName'].OutputValue" --output text)

export TASK_DEF_FAMILY=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='TaskDefinitionFamily'].OutputValue" --output text)

export CODEDEPLOY_APP=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='CodeDeployAppName'].OutputValue" --output text)

export CODEDEPLOY_GROUP=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='CodeDeployDeploymentGroupName'].OutputValue" --output text)

# Verificar que no están vacíos
echo "ECR:   $ECR_REPO_NAME"
echo "Task:  $TASK_DEF_FAMILY"
echo "App:   $CODEDEPLOY_APP"
echo "Group: $CODEDEPLOY_GROUP"
```

---

## 4. Imagen inicial en ECR

```bash
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REPO_URI=$ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME

aws ecr get-login-password --region $AWS_DEFAULT_REGION \
  | docker login --username AWS --password-stdin $REPO_URI

docker build -t $REPO_URI:latest ./apps/api
docker push $REPO_URI:latest
```

---

## 5. Pipeline CI/CD

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/pipeline.yml \
  --stack-name $PIPELINE_STACK_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_DEFAULT_REGION \
  --parameter-overrides \
    GitHubOwner=$GITHUB_OWNER \
    GitHubRepo=$GITHUB_REPO \
    GitHubBranch=$GITHUB_BRANCH \
    ECRRepositoryName=$ECR_REPO_NAME \
    TaskDefinitionFamily=$TASK_DEF_FAMILY \
    CodeDeployAppName=$CODEDEPLOY_APP \
    CodeDeployDeploymentGroupName=$CODEDEPLOY_GROUP
```

---

## 6. URL de la app

```bash
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='AppURL'].OutputValue" --output text
```

---

## Estado del pipeline

```bash
aws codepipeline get-pipeline-state \
  --name $PIPELINE_STACK_NAME-pipeline \
  --region $AWS_DEFAULT_REGION \
  --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" \
  --output table
```

---

## Logs

```bash
# CodeBuild (errores de build)
aws logs tail /aws/codebuild/$PIPELINE_STACK_NAME-build \
  --region $AWS_DEFAULT_REGION --follow

# App en ECS
aws logs tail /ecs/app-demo --region $AWS_DEFAULT_REGION --follow
```

---

## Destruir todo

```bash
aws cloudformation delete-stack --stack-name $PIPELINE_STACK_NAME --region $AWS_DEFAULT_REGION
aws cloudformation wait stack-delete-complete --stack-name $PIPELINE_STACK_NAME --region $AWS_DEFAULT_REGION

# Vaciar ECR antes de borrar el stack base (no se puede borrar si tiene imágenes)
aws ecr batch-delete-image \
  --repository-name $ECR_REPO_NAME --region $AWS_DEFAULT_REGION \
  --image-ids "$(aws ecr list-images --repository-name $ECR_REPO_NAME \
    --region $AWS_DEFAULT_REGION --query 'imageIds[*]' --output json)" 2>/dev/null || true

aws cloudformation delete-stack --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION
```
