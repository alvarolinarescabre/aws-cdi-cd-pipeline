# 🏗️ Arquitectura - Monorepo AWS CI/CD Pipeline

Documentación de la arquitectura y organización del monorepo.

## 📊 Estructura de Directorios

```
aws-cdi-cd-pipeline/              # Raíz del monorepo
│
├── 📁 apps/                       # Aplicaciones desplegables
│   │                             # (pueden ser múltiples)
│   └── api/
│       ├── app.py               # Código de la aplicación
│       ├── Dockerfile           # Empaquetado de la app
│       ├── requirements.txt      # Dependencias
│       └── .dockerignore         # Archivos a ignorar
│
├── 📁 services/                  # Servicios de infraestructura
│   │                            # (no son apps, son config)
│   └── pipeline/
│       └── buildspec.yml        # Instrucciones de build para CodeBuild
│
├── 📁 infrastructure/            # Configuración e scripts
│   ├── .env.example             # Template de variables (NO incluir .env real)
│   └── scripts/
│       ├── test-build.sh        # Script para probar build local
│       ├── pre-commit-check.sh  # Script de validación
│       └── deploy.sh            # (Opcional) Script de deploy manual
│
├── 📁 docs/                     # Documentación
│   ├── README.md               # Guía completa
│   ├── QUICKSTART.md           # Setup rápido
│   └── ARCHITECTURE.md         # Este archivo
│
├── .gitignore                  # Reglas Git
├── .dockerignore               # Reglas Docker (opcional)
└── README.md                   # Overview del proyecto
```

---

## 🔄 Flujo de Datos y Ejecución

### 1. Desarrollo Local

```
Developer edita código
    ↓
git add / commit / push
    ↓
GitHub (rama main)
    ↓
[Webhook trigger]
```

### 2. Pipeline Execution

```
GitHub Webhook
    ↓
AWS CodePipeline (orquestador)
    ├─ Source Stage
    │  └─ Clona repositorio
    │
    ├─ Build Stage
    │  └─ CodeBuild ejecuta: services/pipeline/buildspec.yml
    │     ├─ Pre-build: ECR login
    │     ├─ Build: docker build ./apps/api
    │     └─ Post-build: docker push + crea imagedefinitions.json
    │
    └─ Deploy Stage
       └─ ECS Deploy
          ├─ Lee imagedefinitions.json
          └─ Actualiza Task Definition
             └─ Fargate inicia nuevo contenedor
```

### 3. Runtime

```
Fargate Container
    ├─ apps/api/app.py en ejecución
    ├─ Escuchando puerto 80
    └─ Accesible vía IP pública
```

---

## 📦 Responsabilidades por Carpeta

### `apps/`
**Qué es:** Aplicaciones desplegables  
**Quién las modifica:** Desarrolladores  
**Cómo se usan:** CodeBuild ejecuta `docker build ./apps/api`  

**Archivos típicos:**
- `app.py` - Código principal
- `Dockerfile` - Empaquetado
- `requirements.txt` - Dependencias
- `.dockerignore` - Optimización

**Ejemplo de expansión:**
```
apps/
├── api/                  # API principal
├── worker/              # Job worker (nuevo)
├── scheduler/           # Scheduled tasks (nuevo)
└── frontend/            # React app (futuro)
```

### `services/`
**Qué es:** Configuración de servicios de infraestructura  
**Quién la modifica:** DevOps / SRE  
**Cómo se usa:** CodeBuild referencia `services/pipeline/buildspec.yml`  

**Estructura posible:**
```
services/
├── pipeline/
│   └── buildspec.yml    # Build stage
├── deploy/              # Deploy scripts (futuro)
└── monitoring/          # CloudWatch config (futuro)
```

### `infrastructure/`
**Qué es:** Configuración y scripts operacionales  
**Quién la modifica:** DevOps / SRE  
**Cómo se usa:** Scripts locales y de referencia  

**Archivos:**
- `.env.example` - Variables template
- `scripts/test-build.sh` - Prueba local
- `scripts/pre-commit-check.sh` - Validación

**Expansión posible:**
```
infrastructure/
├── terraform/           # IaC para AWS (futuro)
├── kubernetes/          # K8s manifests (futuro)
├── monitoring/          # CloudWatch dashboards (futuro)
└── scripts/
    ├── test-build.sh
    ├── pre-commit-check.sh
    ├── deploy.sh        # Deploy manual
    └── rollback.sh      # Rollback manual
```

### `docs/`
**Qué es:** Documentación  
**Quién la mantiene:** Todos  
**Cómo se usa:** Referencia para setup y troubleshooting  

**Archivos:**
- `README.md` - Guía completa (paso a paso AWS)
- `QUICKSTART.md` - 10 pasos rápidos
- `ARCHITECTURE.md` - Este archivo

---

## 🔌 Conexiones entre Componentes

### Git → CodePipeline
- **Activador:** Webhook en rama `main`
- **Qué se detecta:** Push a `main`
- **Qué hace:** Inicia pipeline automáticamente

### CodePipeline → CodeBuild
- **Qué pasa:** CodePipeline invoca build stage
- **Qué ejecuta:** `services/pipeline/buildspec.yml`
- **Qué necesita:** Variables de entorno (AWS_ACCOUNT_ID, etc)

### CodeBuild → ECR
- **Qué hace CodeBuild:**
  1. Build: `docker build ./apps/api`
  2. Tag: `$ECR_URI:commit-hash` y `:latest`
  3. Push: Sube imágenes a ECR
  4. Generate: Crea `imagedefinitions.json`

### CodePipeline → ECS
- **Qué pasa:** Deploy stage ejecuta
- **Qué lee:** `imagedefinitions.json`
- **Qué actualiza:** ECS Task Definition
- **Resultado:** Fargate lanza nuevo contenedor

### ECS → Fargate
- **Qué pasa:** ECS orquesta la actualización
- **Qué hace Fargate:** Inicia contenedor con nueva imagen
- **Resultado:** Tu app está corriendo

---

## 🔐 Flujo de Permisos IAM

```
CodeBuild Role
    ├─ EC2 (para ejecutarse)
    ├─ ECR (para push/pull)
    │  └─ AmazonEC2ContainerRegistryPowerUser
    ├─ CloudWatch (para logs)
    └─ S3 (para artifacts)

CodePipeline Role
    ├─ CodeBuild (para invocar)
    ├─ ECS (para deploy)
    └─ S3 (para artifacts)

ECS Task Role
    ├─ ECR (para pull image)
    ├─ CloudWatch (para logs)
    └─ Application Permissions (según la app)
```

---

## 📝 Variables de Configuración

### Requeridas por CodeBuild

```
AWS_ACCOUNT_ID     = 123456789012      (12 dígitos)
AWS_DEFAULT_REGION = us-east-1         (tu región)
IMAGE_REPO_NAME    = mi-app-repo       (nombre ECR)
```

### Derivadas (calculadas)

```
REPOSITORY_URI = $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
COMMIT_HASH    = Primeros 7 chars del commit
IMAGE_TAG      = $COMMIT_HASH o latest
```

### ECS Configuration

```
ECS_CLUSTER_NAME    = mi-cluster-ecs
ECS_SERVICE_NAME    = mi-servicio-ecs
ECS_CONTAINER_NAME  = mi-contenedor-app  ← CRÍTICO: debe coincidir
ECS_TASK_FAMILY     = mi-task-def
```

---

## 🚀 Escalabilidad - Cómo Expandir

### Agregar Más Apps al Monorepo

```bash
# 1. Crear nueva app
mkdir -p apps/worker
cd apps/worker
touch app.py Dockerfile requirements.txt

# 2. Crear ECR repo para esta app
# AWS Console → ECR → Create repository: mi-worker-repo

# 3. Actualizar buildspec.yml para incluir esta app
# (o crear build stage separada)

# 4. Crear servicio ECS para esta app
```

### Agregar Múltiples Pipelines

```
Opción A: Un pipeline, múltiples stages
└─ Build Stage 1: apps/api
└─ Build Stage 2: apps/worker
└─ Deploy Stage 1: ECS Service 1
└─ Deploy Stage 2: ECS Service 2

Opción B: Múltiples pipelines
└─ Pipeline 1: api (services/pipeline/buildspec-api.yml)
└─ Pipeline 2: worker (services/pipeline/buildspec-worker.yml)
```

### Agregar Ambientes (dev, staging, prod)

```
infrastructure/
├── terraform/
│   ├── dev/
│   │   ├── variables.tf
│   │   └── main.tf
│   ├── staging/
│   │   ├── variables.tf
│   │   └── main.tf
│   └── prod/
│       ├── variables.tf
│       └── main.tf
```

---

## 🔍 Monitoreo y Observabilidad

### CodePipeline Metrics
- **Ejecuciones exitosas/fallidas**
- **Duración de cada stage**

### CodeBuild Metrics
- **Tiempo de build**
- **Tasa de fallo**
- **Logs en CloudWatch**

### ECS Metrics
- **Número de tareas corriendo**
- **CPU y memoria utilizada**
- **Health checks**

### Application Metrics
- **Requests/segundo**
- **Latencia**
- **Errores**

---

## 📚 Comparativa: Monorepo vs Múltiples Repos

### Monorepo (Este proyecto)
✅ **Ventajas:**
- Cambios atómicos en múltiples servicios
- Testing integrado
- Documentación centralizada
- Fácil de mantener para proyectos pequeños/medianos

❌ **Desventajas:**
- A veces builds innecesarias (solución: path filtering)
- Todos usan las mismas dependencias

### Múltiples Repos
✅ **Ventajas:**
- Independencia total entre servicios
- Ciclos de release diferentes
- Equipos completamente desacoplados

❌ **Desventajas:**
- Más complejo de coordinar
- Más repositorios que mantener
- Testing integrado más difícil

**→ Recomendación:** Monorepo para <5 servicios. Múltiples repos para >10 servicios.

---

## 🎯 Decisiones de Diseño

### ¿Por qué `apps/` y no `services/`?
- `services/` → Usualmente significa microservicios arquitectónicamente independientes
- `apps/` → Múltiples aplicaciones dentro del mismo proyecto (monorepo pattern)

### ¿Por qué `services/pipeline/` y no `ci/`?
- Indica que es un "servicio" de infraestructura
- Fácil de expandir: `services/pipeline/`, `services/deploy/`, etc

### ¿Por qué scripts en `infrastructure/scripts/`?
- Separar configuración (`.env.example`) de scripts ejecutables
- Fácil encontrar scripts operacionales

### ¿Por qué no guardar `.env` con valores reales?
- **Seguridad:** Credenciales en el repo es un riesgo
- **Práctica:** Usar `.env.example` como template
- **CI/CD:** Las variables vienen de CodeBuild configuration

---

## 🔗 Recursos Externos

- [AWS CodePipeline Docs](https://docs.aws.amazon.com/codepipeline/)
- [AWS CodeBuild Buildspec Reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)
- [ECS Task Definition Parameters](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html)
- [Monorepo Patterns](https://en.wikipedia.org/wiki/Monorepo)

---

**Documento creado:** 2026-06-30  
**Última actualización:** 2026-06-30
