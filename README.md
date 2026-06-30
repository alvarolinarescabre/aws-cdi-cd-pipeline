# AWS CI/CD Pipeline — ECS Fargate + CodeDeploy Blue/Green

Flujo completo: **GitHub → CodePipeline → CodeBuild → CodeDeploy → ECS Fargate**

```
push a main
    │
    ▼
CodePipeline
  ├── Source  (descarga código desde GitHub)
  ├── Build   (CodeBuild: docker build → push ECR → genera artefactos)
  └── Deploy  (CodeDeployToECS: Blue/Green en Fargate)
```

---

## Pre-requisitos

```bash
# Verifica que tienes lo necesario
aws --version
docker --version
aws sts get-caller-identity   # debe mostrar tu Account ID

# Exporta variables base (ajusta a tu cuenta)
export AWS_DEFAULT_REGION=eu-west-1
export STACK_NAME=app-demo-stack
export PIPELINE_STACK_NAME=app-demo-pipeline
export GITHUB_OWNER=alvarolinarescabre
export GITHUB_REPO=aws-ci-cd-pipeline
export GITHUB_BRANCH=main
```

---

## Paso 1 — Guardar el token de GitHub en Secrets Manager

Crea un Personal Access Token en GitHub con permisos `repo` y `admin:repo_hook`.

```bash
aws secretsmanager create-secret \
  --name github-token \
  --secret-string '{"token":"ghp_TU_TOKEN_AQUI"}' \
  --region $AWS_DEFAULT_REGION
```

---

## Paso 2 — Desplegar infraestructura base (ECR + ECS + ALB + CodeDeploy)

```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/stack.yml \
  --stack-name $STACK_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $AWS_DEFAULT_REGION

# Verificar
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].StackStatus" \
  --output text
# Debe mostrar: CREATE_COMPLETE
```

---

## Paso 3 — Obtener outputs del stack base

```bash
export ECR_REPO_NAME=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='ECRRepositoryName'].OutputValue" \
  --output text)

export TASK_DEF_FAMILY=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='TaskDefinitionFamily'].OutputValue" \
  --output text)

export CODEDEPLOY_APP=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='CodeDeployAppName'].OutputValue" \
  --output text)

export CODEDEPLOY_GROUP=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME --region $AWS_DEFAULT_REGION \
  --query "Stacks[0].Outputs[?OutputKey=='CodeDeployDeploymentGroupName'].OutputValue" \
  --output text)

echo "ECR Repo:        $ECR_REPO_NAME"
echo "Task Def Family: $TASK_DEF_FAMILY"
echo "CodeDeploy App:  $CODEDEPLOY_APP"
echo "CodeDeploy Group:$CODEDEPLOY_GROUP"
```

Los cuatro deben tener valor antes de continuar.

---

## Paso 4 — Subir imagen inicial a ECR

```bash
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REPO_URI=$ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$ECR_REPO_NAME

aws ecr get-login-password --region $AWS_DEFAULT_REGION \
  | docker login --username AWS --password-stdin $REPO_URI

docker build -t $REPO_URI:latest ./apps/api
docker push $REPO_URI:latest
```

---

## Paso 5 — Desplegar el pipeline CI/CD

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
    GitHubOAuthTokenSecretName=github-token \
    ECRRepositoryName=$ECR_REPO_NAME \
    TaskDefinitionFamily=$TASK_DEF_FAMILY \
    CodeDeployAppName=$CODEDEPLOY_APP \
    CodeDeployDeploymentGroupName=$CODEDEPLOY_GROUP

# Verificar
aws cloudformation describe-stacks \
  --stack-name $PIPELINE_STACK_NAME \
  --query "Stacks[0].StackStatus" \
  --output text
# Debe mostrar: CREATE_COMPLETE
```

---

## Paso 6 — Verificar la app

```bash
# URL del load balancer
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='AppURL'].OutputValue" \
  --output text
```

Abre esa URL en el navegador — debes ver la respuesta de la app.

---

## Flujo diario (después del setup)

```bash
# 1. Modifica tu código en apps/api/
# 2. Commit y push a main
git add apps/
git commit -m "feat: mi cambio"
git push origin main

# El pipeline se ejecuta automáticamente
# Sigue el progreso en CodePipeline console o con:
aws codepipeline get-pipeline-state \
  --name $PIPELINE_STACK_NAME-pipeline \
  --region $AWS_DEFAULT_REGION \
  --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" \
  --output table
```

---

## Logs de errores

```bash
# CodeBuild
aws logs tail /aws/codebuild/$PIPELINE_STACK_NAME-build \
  --region $AWS_DEFAULT_REGION --follow

# ECS containers
aws logs tail /ecs/app-demo \
  --region $AWS_DEFAULT_REGION --follow
```

---

## Troubleshooting

| Error | Causa | Solución |
|-------|-------|----------|
| `CannotPullContainerError` | ECR sin imagen | Ejecutar Paso 4 |
| `CodeBuild exit status 1` | Ver logs de CodeBuild | `aws logs tail /aws/codebuild/...` |
| `ResourceExistenceCheck` | Stack en estado fallido | `delete-stack` y volver a crear |
| Webhook no dispara | Token sin permisos `admin:repo_hook` | Regenerar token en GitHub |
