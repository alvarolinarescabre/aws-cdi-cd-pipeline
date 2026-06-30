# AWS CI/CD Pipeline - CodeBuild + CodePipeline + ECS + ECR

Pipeline automatizado para desplegar apps en AWS usando GitHub como fuente.

## 📋 Estructura del Proyecto (Monorepo)

```
.
├── apps/
│   └── api/                    # Aplicación Flask
│       ├── app.py
│       ├── Dockerfile
│       └── requirements.txt
│
├── services/
│   └── pipeline/               # Configuración CodeBuild
│       └── buildspec.yml
│
├── infrastructure/
│   ├── .env.example           # Variables de configuración
│   └── scripts/
│       ├── test-build.sh      # Test local Docker
│       └── pre-commit-check.sh # Validación pre-push
│
├── docs/
│   ├── README.md              # Este documento
│   ├── QUICKSTART.md          # Guía rápida
│   └── ARCHITECTURE.md        # Diagrama de arquitectura
│
├── .gitignore
└── README.md                  # Documentación raíz
```

## 🔧 Flujo del Pipeline

```
GitHub (main branch)
  ↓ (webhook)
CodePipeline (source)
  ↓
CodeBuild (services/pipeline/buildspec.yml)
  ├─ pre_build: Login a ECR
  ├─ build: Docker build desde apps/api
  ├─ post_build: Docker push + genera imagedefinitions.json
  ↓
CodePipeline (deploy)
  ↓
ECS (actualiza servicio)
  ↓
Fargate (ejecuta contenedor)
```

---

## 📌 PASOS EN ORDEN - Guía Completa

### Paso 1: Preparar el Repositorio GitHub

1. Crea un repositorio en GitHub
2. Clona este proyecto en tu repo
3. Push a la rama `main`:
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Monorepo CI/CD pipeline setup"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/tu-repo.git
   git push -u origin main
   ```

### Paso 2: Crear Repositorio en Amazon ECR

1. Ve a **AWS Console** → **Amazon ECR** → **Repositories**
2. Click **Create repository**
3. Nombre: `mi-app-repo`
4. Deja todo por defecto, click **Create**
5. **COPIA LA URI DEL REPOSITORIO** (ejemplo: `123456789.dkr.ecr.us-east-1.amazonaws.com/mi-app-repo`)

### Paso 3: Crear Infraestructura ECS (Fargate)

#### 3.1 Crear Cluster
1. Ve a **Amazon ECS** → **Clusters** → **Create cluster**
2. Nombre: `mi-cluster-ecs`
3. Infrastructure: Selecciona **AWS Fargate**
4. Click **Create**

#### 3.2 Crear Task Definition
1. Ve a **Amazon ECS** → **Task Definitions** → **Create new task definition**
2. **Nombre de familia:** `mi-task-def`
3. **Tipo de lanzamiento:** AWS Fargate
4. **Sistema Operativo:** Linux/X86_64
5. **CPU:** 256
6. **Memoria:** 512
7. **Rol de ejecución de tareas:** Crear nuevo rol (por defecto está bien)
8. **Contenedor** - Click **Add container**:
   - **Nombre:** `mi-contenedor-app` ⚠️ **IMPORTANTE: Este nombre debe coincidir con buildspec.yml**
   - **URI de imagen:** Pega la URI de ECR + `:latest` 
     - Ejemplo: `123456789.dkr.ecr.us-east-1.amazonaws.com/mi-app-repo:latest`
   - **Mapeos de puertos:**
     - **Puerto del contenedor:** 80
     - **Protocolo:** tcp
   - Click **Add**
9. Click **Create**

#### 3.3 Crear Servicio
1. En tu cluster `mi-cluster-ecs`, ve a **Services** → **Create**
2. **Tipo de lanzamiento:** Fargate
3. **Task Definition:** Selecciona `mi-task-def` - última revisión
4. **Nombre del servicio:** `mi-servicio-ecs`
5. **Deseado (Desired count):** 1
6. **Redes:**
   - Selecciona tu VPC por defecto
   - **Security Group:** Crea uno nuevo o usa existente que permita puerto 80
   - **IP pública:** Activa **Activar IP pública**
7. Click **Create**

### Paso 4: Configurar Permisos IAM para CodeBuild

1. Ve a **IAM** → **Roles**
2. Busca el rol de CodeBuild (lo crearemos en el siguiente paso, suele llamarse `codebuild-mi-proyecto-service-role`)
3. Una vez encontrado, click en él
4. Ve a **Attach policies**
5. Busca y adjunta: `AmazonEC2ContainerRegistryPowerUser`

### Paso 5: Crear Pipeline en CodePipeline

#### 5.1 Crear Pipeline
1. Ve a **AWS CodePipeline** → **Create pipeline**
2. **Nombre:** `mi-pipeline-github`
3. **Ejecutor de servicio:** Crea nuevo rol
4. Click **Next**

#### 5.2 Configurar Fase de Origen (Source)
1. **Proveedor de origen:** GitHub (conectarse con GitHub App)
2. Click **Conectarse a GitHub**
   - Se abrirá una ventana nueva
   - Haz clic en **Install a new GitHub App**
   - Nombre de app: `aws-pipeline-app`
   - Autoriza el acceso
3. **Repositorio:** Selecciona tu repo
4. **Rama:** `main`
5. **Cambio de activación:** Marca **Webhooks**
6. Click **Next**

#### 5.3 Configurar Fase de Build (CodeBuild)
1. **Proveedor de compilación:** AWS CodeBuild
2. Click **Crear proyecto en línea**
   - **Nombre del proyecto:** `mi-proyecto-build`
   - **Entorno:** Imagen gestionada
   - **Sistema operativo:** Amazon Linux 2
   - **Runtime:** Standard
   - **Imagen:** Última disponible (ej: `aws/codebuild/amazonlinux2-x86_64-standard:5.0`)
   - **Privilegios personalizados:** ✅ **ACTIVA ESTA CASILLA** (necesario para Docker)
   - **Archivo buildspec:** `services/pipeline/buildspec.yml` (indicar la ruta del monorepo)
   - **Variables de Entorno - Agregadas:**
     ```
     AWS_ACCOUNT_ID = Tu ID de cuenta (12 dígitos)
     AWS_DEFAULT_REGION = us-east-1 (o tu región)
     IMAGE_REPO_NAME = mi-app-repo
     ```
   - Click **Continuar con CodePipeline**
3. Click **Next**

#### 5.4 Configurar Fase de Deploy (ECS)
1. **Proveedor de implementación:** Amazon ECS
2. **Cluster:** `mi-cluster-ecs`
3. **Servicio:** `mi-servicio-ecs`
4. **Archivo de definición de imagen:** `imagedefinitions.json`
5. Click **Next** → **Crear pipeline**

✅ **¡Pipeline creado!**

---

## 🧪 Probar el Pipeline

1. Realiza un cambio en tu app local (ej: modifica el mensaje en `apps/api/app.py`)
2. Commit y push a `main`:
   ```bash
   git add .
   git commit -m "Update: change message"
   git push origin main
   ```
3. Ve a **CodePipeline** → `mi-pipeline-github`
4. Verás el pipeline ejecutándose automáticamente
5. Espera a que complete las fases (5-10 minutos)

### Ver logs de CodeBuild
- En CodePipeline, cuando la fase de Build esté en ejecución, click en **Details**
- Verás los logs en tiempo real

### Acceder a la app en ECS
1. Ve a **ECS** → **Clusters** → `mi-cluster-ecs` → **Services** → `mi-servicio-ecs`
2. Ve a **Tasks** y haz click en la tarea activa
3. En **Network**, copia la **IP pública**
4. Abre en navegador: `http://TU_IP_PUBLICA`

---

## 📝 Archivo Crítico: `services/pipeline/buildspec.yml`

Este archivo controla **todo el proceso de build**:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      # Login a ECR
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      # Variables necesarias
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${COMMIT_HASH:=latest}
      
  build:
    commands:
      # Construir imagen desde apps/api
      - docker build -t $REPOSITORY_URI:latest ./apps/api
      - docker tag $REPOSITORY_URI:latest $REPOSITORY_URI:$IMAGE_TAG
      
  post_build:
    commands:
      # Subir a ECR
      - docker push $REPOSITORY_URI:latest
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      # Generar manifiesto para ECS
      # ⚠️ El nombre debe coincidir con Task Definition
      - printf '[{"name":"mi-contenedor-app","imageUri":"%s"}]' $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

**Variables clave:**
- `AWS_ACCOUNT_ID`: Tu ID de AWS (12 dígitos)
- `IMAGE_REPO_NAME`: Nombre ECR (`mi-app-repo`)
- `AWS_DEFAULT_REGION`: Región AWS (ej: `us-east-1`)

---

## ⚠️ Checklist de Validación

- [ ] ECR repositorio creado
- [ ] ECS Cluster creado
- [ ] ECS Task Definition creada con nombre de contenedor: `mi-contenedor-app`
- [ ] ECS Service creado con IP pública activada
- [ ] Rol de CodeBuild tiene política `AmazonEC2ContainerRegistryPowerUser`
- [ ] CodeBuild tiene privilegios personalizados activados
- [ ] GitHub App conectada a AWS
- [ ] buildspec.yml apunta a: `services/pipeline/buildspec.yml`
- [ ] Pipeline ejecutado exitosamente
- [ ] App accesible desde IP pública

---

## 🔧 Troubleshooting

### Error: "Docker-in-Docker failed"
- Ve a CodeBuild → Proyecto → **Activar Privilegios personalizados**

### Error: "Access denied to ECR"
- Verifica que el rol de CodeBuild tiene `AmazonEC2ContainerRegistryPowerUser`

### La tarea en ECS no inicia
- Revisa los logs: ECS → Cluster → Service → Tasks → Ver logs
- Verifica que el nombre del contenedor sea exactamente `mi-contenedor-app`

### El webhook no dispara el pipeline
- En GitHub → Settings → **Webhooks** → Verifica que AWS esté en la lista
- Asegúrate de pushar a rama `main`

### Error: buildspec.yml no encontrado
- Verifica que en CodeBuild especificaste: `services/pipeline/buildspec.yml`

---

## 📚 Arquitectura Monorepo

```
Monorepo Structure:
├─ apps/          → Aplicaciones desplegables
├─ services/      → Servicios de infraestructura (pipelines, etc)
├─ infrastructure/→ Configuración y scripts
├─ docs/          → Documentación
└─ Root Files    → Config global (.gitignore, etc)
```

---

## 🎯 Próximos Pasos Avanzados

- [ ] Agregar etapa de Testing (antes de deploy)
- [ ] Configurar múltiples ambientes (dev, staging, prod)
- [ ] Agregar Auto Scaling a ECS Service
- [ ] Configurar CloudWatch para monitoreo
- [ ] Agregar notificaciones SNS en fallos
- [ ] Expandir monorepo con más apps/microservicios

---

**Hecho con ❤️ para DevOps simples y funcionales.**
