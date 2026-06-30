# AWS CI/CD Pipeline - Monorepo Structure

Pipeline automatizado CI/CD para desplegar microservicios en AWS usando GitHub como fuente. Estructura de **monorepo** para organizar múltiples apps y servicios.

## 📋 Estructura del Monorepo

```
aws-cdi-cd-pipeline/
│
├── 📁 apps/                          # 🚀 Aplicaciones desplegables
│   └── api/
│       ├── app.py                   # Flask app
│       ├── Dockerfile               # Empaquetado
│       └── requirements.txt          # Dependencias
│
├── 📁 services/                      # ⚙️ Servicios de infraestructura
│   └── pipeline/
│       └── buildspec.yml            # Motor CodeBuild
│
├── 📁 infrastructure/                # 🔧 Configuración & Scripts
│   ├── cloudformation/
│   │   ├── stack.yml                # ECR + ECS + VPC
│   │   └── pipeline.yml             # CodePipeline + CodeBuild
│   ├── .env.example                 # Variables de configuración
│   └── scripts/
│       ├── deploy-stack.sh          # Deploy infraestructura
│       ├── test-build.sh            # Test local Docker
│       └── pre-commit-check.sh      # Validación pre-push
│
├── 📁 docs/                          # 📚 Documentación
│   ├── README.md                    # Guía completa (copiar desde aquí)
│   ├── QUICKSTART.md                # 10 pasos rápidos
│   └── ARCHITECTURE.md              # Diagrama
│
├── .gitignore                        # Git ignore rules
└── README.md                         # Este archivo (overview)
```

---

## 🎯 Quick Links

| Descripción | Ruta | Descripción |
|-------------|------|------------|
| 📚 **Guía Completa** | [docs/README.md](docs/README.md) | Pasos detallados para setup en AWS |
| ⚡ **Quick Start** | [docs/QUICKSTART.md](docs/QUICKSTART.md) | 10 pasos en 30 minutos |
| 🔧 **Variables Config** | [infrastructure/.env.example](infrastructure/.env.example) | Template de configuración |
| 🧪 **Test Local** | [infrastructure/scripts/test-build.sh](infrastructure/scripts/test-build.sh) | Valida Docker build localmente |
| ✅ **Pre-Commit Check** | [infrastructure/scripts/pre-commit-check.sh](infrastructure/scripts/pre-commit-check.sh) | Valida antes de push |

---

## 🚀 Cómo Empezar

### 1️⃣ Leer Documentación
```bash
# Guía paso-a-paso completa
cat docs/README.md

# Quick start (si tienes prisa)
cat docs/QUICKSTART.md
```

### 2️⃣ Preparar Localmente
```bash
# Validar estructura
./infrastructure/scripts/pre-commit-check.sh

# Probar Docker build local
./infrastructure/scripts/test-build.sh
```

### 3️⃣ Setup en AWS
Sigue los **3 pasos** en [infrastructure/README.md](infrastructure/README.md):
1. Desplegar stack base con CloudFormation (ECR + ECS + VPC)
2. Build y push de imagen inicial a ECR
3. Desplegar pipeline de CI/CD con CloudFormation (CodePipeline + CodeBuild)

### 4️⃣ Monitorear
- CodePipeline console
- ECS tasks
- CloudWatch logs

---

## 📁 Qué Hay en Cada Carpeta

### `apps/api/` - Tu Aplicación Flask
```
apps/api/
├── app.py           # Flask endpoints
├── Dockerfile       # Empaquetado
└── requirements.txt # Dependencias
```
**Editables:** Modifica aquí tu código

### `services/pipeline/` - Referencia
```
services/pipeline/
└── buildspec.yml    # Definición de build (integrado en pipeline.yml)
```
**Nota:** Este archivo se usa como referencia; la plantilla `pipeline.yml` lo incorpora directamente.

### `infrastructure/` - Plantillas & Scripts
```
infrastructure/
├── cloudformation/
│   ├── stack.yml           # ECR + ECS + Fargate + VPC
│   └── pipeline.yml        # CodePipeline + CodeBuild
├── .env.example            # Template de variables (opcional)
└── scripts/
    ├── deploy-stack.sh     # Despliegue rápido
    ├── test-build.sh       # Valida Docker localmente
    └── pre-commit-check.sh # Valida antes de push
```
**Despliegue:** Lee [infrastructure/README.md](infrastructure/README.md) para comandos listos para copiar/pegar

### `docs/` - Documentación
```
docs/
├── README.md       # Guía completa (copia a raíz)
├── QUICKSTART.md   # Versión rápida
└── ARCHITECTURE.md # Diagrama (crear si necesario)
```

---

## 🔄 Flujo del Pipeline

```
┌─────────────────────────────────────────┐
│ Despliegas CloudFormation (2 pilas)    │
│ 1. stack.yml (infraestructura base)    │
│ 2. pipeline.yml (CI/CD)                │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ Haces push a GitHub (rama main)        │
│ → Webhook dispara CodePipeline         │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ CodeBuild:                             │
│ • Descarga código desde GitHub         │
│ • Construye Docker image               │
│ • Publica en ECR                       │
│ • Actualiza ECS service                │
└────────────┬────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│ ECS Fargate:                           │
│ • Descarga imagen nueva desde ECR      │
│ • Inicia nuevo contenedor              │
│ • App disponible en IP pública         │
└─────────────────────────────────────────┘
```

---

## 🛠️ Para Desarrolladores

### Agregar una nueva app al monorepo
```bash
mkdir -p apps/mi-nueva-app
# Crea: Dockerfile, app.py, requirements.txt
# Actualiza: services/pipeline/buildspec.yml (si es necesario)
```

### Cambiar la app principal
1. Modifica `apps/api/app.py`
2. Ejecuta: `./infrastructure/scripts/test-build.sh`
3. Push a `main`
4. El pipeline se ejecutará automáticamente

### Ver logs del pipeline
```
AWS Console → CodePipeline → Tu pipeline → Details
```

---

## ⚙️ Parámetros Clave en CloudFormation

| Parámetro | Stack | Ejemplo | Descripción |
|-----------|-------|---------|-------------|
| `EnvironmentName` | stack.yml | `app-demo` | Prefijo para recursos |
| `ContainerImage` | stack.yml | ECR URI | Imagen inicial a desplegar |
| `GitHubOwner` | pipeline.yml | `tu-usuario` | Usuario GitHub |
| `GitHubRepo` | pipeline.yml | `aws-cdi-cd-pipeline` | Nombre del repo |
| `GitHubBranch` | pipeline.yml | `main` | Rama a monitorear |

---

## ✅ Checklist de Despliegue

### Paso 0: Pre-requisitos
```bash
# Verificar AWS CLI instalado y configurado
aws --version
aws sts get-caller-identity   # Debe mostrar tu Account ID y ARN

# Verificar Docker instalado y corriendo
docker --version
docker info

# Verificar Git configurado
git config user.name
git config user.email
```

### Paso 1: Configurar variables de entorno
```bash
# Exportar variables (ajusta los valores a tu cuenta)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_DEFAULT_REGION=eu-west-1         # Cambia a tu región
export IMAGE_REPO_NAME=api-repo              # Nombre del repo ECR
export STACK_NAME=app-demo-stack             # Nombre del stack base
export PIPELINE_STACK_NAME=app-demo-pipeline # Nombre del stack pipeline
export GITHUB_OWNER=tu-usuario-github        # Tu usuario/org de GitHub
export GITHUB_REPO=aws-cdi-cd-pipeline       # Nombre del repositorio
export GITHUB_BRANCH=main
```

### Paso 2: Guardar GitHub Token en Secrets Manager
```bash
# Crea un Personal Access Token en GitHub:
# GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# Permisos requeridos: repo (full), admin:repo_hook

# Guarda el token en AWS Secrets Manager (nombre por defecto: "github-token")
aws secretsmanager create-secret \
  --name github-token \
  --secret-string '{"token":"ghp_TU_TOKEN_AQUI"}' \
  --region $AWS_DEFAULT_REGION
```

### Paso 3: Desplegar infraestructura base (ECR + ECS + VPC)
```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/stack.yml \
  --stack-name $STACK_NAME \
  --region $AWS_DEFAULT_REGION \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EnvironmentName=app-demo \
    AppName=api \
    ContainerName=api-container \
    ECRRepositoryName=$IMAGE_REPO_NAME

# Verificar que el stack se creó correctamente
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].StackStatus" \
  --output text
# Debe mostrar: CREATE_COMPLETE

# Obtener outputs del stack (ECR URI, cluster, servicio)
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs" \
  --output table
```

### Paso 4: Build y push de imagen inicial a ECR
```bash
# Obtener el ECR URI del output del stack
export ECR_URI=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='RepositoryUri'].OutputValue" \
  --output text)

echo "ECR URI: $ECR_URI"

# Autenticarse en ECR
aws ecr get-login-password --region $AWS_DEFAULT_REGION \
  | docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

# Construir la imagen Docker desde apps/api
docker build -t $IMAGE_REPO_NAME:latest ./apps/api

# Etiquetar con el URI de ECR
docker tag $IMAGE_REPO_NAME:latest $ECR_URI:latest

# Subir la imagen a ECR
docker push $ECR_URI:latest

# Verificar que la imagen está en ECR
aws ecr describe-images \
  --repository-name $IMAGE_REPO_NAME \
  --region $AWS_DEFAULT_REGION \
  --query "imageDetails[*].{Tag:imageTags[0],PushedAt:imagePushedAt}" \
  --output table
```

### Paso 5: Obtener nombres de recursos ECS del stack base
```bash
# Necesarios como parámetros para el pipeline
export ECS_CLUSTER=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ClusterName'].OutputValue" \
  --output text)

export ECS_SERVICE=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ServiceName'].OutputValue" \
  --output text)

echo "Cluster: $ECS_CLUSTER"
echo "Servicio: $ECS_SERVICE"
```

### Paso 6: Desplegar pipeline de CI/CD (CodePipeline + CodeBuild)
```bash
aws cloudformation deploy \
  --template-file infrastructure/cloudformation/pipeline.yml \
  --stack-name $PIPELINE_STACK_NAME \
  --region $AWS_DEFAULT_REGION \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    GitHubOwner=$GITHUB_OWNER \
    GitHubRepo=$GITHUB_REPO \
    GitHubBranch=$GITHUB_BRANCH \
    GitHubTokenSecret=github-token \
    ECRRepositoryName=$IMAGE_REPO_NAME \
    ECSClusterName=$ECS_CLUSTER \
    ECSServiceName=$ECS_SERVICE \
    ContainerName=api-container

# Verificar que el pipeline se creó correctamente
aws cloudformation describe-stacks \
  --stack-name $PIPELINE_STACK_NAME \
  --query "Stacks[0].StackStatus" \
  --output text
# Debe mostrar: CREATE_COMPLETE
```

### Paso 7: Verificar primera ejecución del pipeline
```bash
# Obtener nombre del pipeline
export PIPELINE_NAME=$(aws cloudformation describe-stacks \
  --stack-name $PIPELINE_STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='PipelineName'].OutputValue" \
  --output text)

# Ver estado actual del pipeline
aws codepipeline get-pipeline-state \
  --name $PIPELINE_NAME \
  --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" \
  --output table

# Ver URL de la app desplegada
aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query "Stacks[0].Outputs[?contains(OutputKey,'URL') || contains(OutputKey,'Endpoint')].{Key:OutputKey,Value:OutputValue}" \
  --output table
```

---

### Para cambios en la app (flujo diario)
```bash
# 1. Validar estructura del monorepo
./infrastructure/scripts/pre-commit-check.sh

# 2. Probar Docker build localmente antes de pushear
./infrastructure/scripts/test-build.sh
# Accede a: http://localhost para verificar que la app responde

# 3. Commit y push (dispara el pipeline automáticamente)
git add apps/
git commit -m "feat: descripción de tu cambio"
git push origin main

# 4. Seguir el despliegue en tiempo real
aws codepipeline get-pipeline-state \
  --name $PIPELINE_NAME \
  --query "stageStates[*].{Stage:stageName,Status:latestExecution.status}" \
  --output table

# 5. Ver logs de CodeBuild si hay errores
aws logs tail /aws/codebuild/$PIPELINE_NAME --follow
```

---

## 🎓 Documentación Completa

Para desplegar en AWS con CloudFormation:

👉 **[infrastructure/README.md](infrastructure/README.md)** ← Lee esto para instrucciones paso a paso

Para entender la arquitectura y cómo funciona el pipeline:

👉 **[docs/README.md](docs/README.md)** ← Guía conceptual detallada

---

## 📞 Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| CloudFormation falla | Revisa que tienes credenciales AWS y región correcta |
| ECR access denied | Verifica que el rol CodeBuild tiene permisos ECR |
| La app no inicia | Revisa CloudWatch logs: `/ecs/app-demo/api` |
| Webhook no dispara | Confirma: token GitHub válido en Secrets Manager |
| Imagen no se actualiza | Revisa CodePipeline: Stage Build y outputs |

Más detalles: [infrastructure/README.md](infrastructure/README.md)

---

**🎓 Diseñado para alumnos sin experiencia con AWS. Hecho con ❤️ para DevOps simples y funcionales.**
