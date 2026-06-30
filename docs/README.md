# Arquitectura — AWS CI/CD con CodeDeploy Blue/Green

## Flujo completo

```
Developer
  │
  │  git push origin main
  ▼
GitHub Repository
  │
  │  webhook (HMAC)
  ▼
AWS CodePipeline
  │
  ├─ Stage 1: Source ──────────────── descarga el código como artefacto ZIP
  │
  ├─ Stage 2: Build (CodeBuild) ───── docker build → push ECR
  │                                   genera: taskdef.json, appspec.yaml, imageDetail.json
  │
  └─ Stage 3: Deploy (CodeDeployToECS)
       │  registra nueva Task Definition en ECS
       │  inicia deployment Blue/Green en CodeDeploy
       ▼
    ALB Listener
       │
       ├─ Target Group Blue  (tráfico activo → contenedores viejos)
       └─ Target Group Green (tráfico nuevo → contenedores nuevos)
            │
            │  health checks pasan
            ▼
         ALB redirige 100% del tráfico a Green
            │
            │  5 minutos después
            ▼
         Contenedores Blue terminados
```

---

## Stacks de CloudFormation

### stack.yml — Infraestructura base

| Recurso | Tipo | Descripción |
|---------|------|-------------|
| VPC + Subnets | `AWS::EC2::VPC` | Red privada con 2 subnets públicas en diferentes AZs |
| ALB | `AWS::ElasticLoadBalancingV2::LoadBalancer` | Load balancer internet-facing |
| TargetGroupBlue | `AWS::ElasticLoadBalancingV2::TargetGroup` | Tráfico en producción (inicial) |
| TargetGroupGreen | `AWS::ElasticLoadBalancingV2::TargetGroup` | Tráfico del nuevo deploy |
| ECR Repository | `AWS::ECR::Repository` | Registro de imágenes Docker |
| ECS Cluster | `AWS::ECS::Cluster` | Cluster Fargate |
| Task Definition | `AWS::ECS::TaskDefinition` | Configuración del contenedor (256 CPU, 512 MB) |
| ECS Service | `AWS::ECS::Service` | Servicio con `DeploymentController: CODE_DEPLOY` |
| CodeDeploy App | `AWS::CodeDeploy::Application` | Aplicación CodeDeploy (plataforma ECS) |
| CodeDeploy Group | `AWS::CodeDeploy::DeploymentGroup` | Grupo con config Blue/Green automática |

### pipeline.yml — CI/CD

| Recurso | Tipo | Descripción |
|---------|------|-------------|
| CodeBuild Project | `AWS::CodeBuild::Project` | Build Docker + genera artefactos |
| S3 Bucket | `AWS::S3::Bucket` | Almacén de artefactos del pipeline |
| CodePipeline | `AWS::CodePipeline::Pipeline` | Orquestador Source→Build→Deploy |
| GitHub Webhook | `AWS::CodePipeline::Webhook` | Webhook HMAC registrado automáticamente en GitHub |

---

## Artefactos que genera CodeBuild

CodeBuild produce tres archivos que consume el stage de Deploy:

### imageDetail.json
```json
{"ImageURI": "123456789.dkr.ecr.eu-west-1.amazonaws.com/app-demo-api:a1b2c3d"}
```
CodePipeline lee este archivo y sustituye `<IMAGE1_NAME>` en `taskdef.json`.

### taskdef.json
Task Definition completa con `<IMAGE1_NAME>` como placeholder de la imagen:
```json
{
  "family": "app-demo-task",
  "containerDefinitions": [
    {
      "name": "api-container",
      "image": "<IMAGE1_NAME>",
      "portMappings": [{"containerPort": 80}]
    }
  ],
  ...
}
```

### appspec.yaml
```yaml
version: 0.0
Resources:
  - TargetService:
      Type: "AWS::ECS::Service"
      Properties:
        TaskDefinition: "<TASK_DEFINITION>"
        LoadBalancerInfo:
          ContainerName: "api-container"
          ContainerPort: 80
```
`<TASK_DEFINITION>` es sustituido por CodePipeline con el ARN de la nueva Task Definition registrada.

---

## Blue/Green Deployment

| Fase | Qué ocurre |
|------|-----------|
| **Pre-traffic** | CodeDeploy registra la nueva Task Definition y lanza contenedores en Target Group Green |
| **Health check** | ALB verifica que los contenedores en Green responden en `GET /` |
| **Traffic shift** | ALB redirige 100% del tráfico de Blue a Green (`ECSAllAtOnce`) |
| **Termination** | Los contenedores Blue se terminan tras 5 minutos |

Configuración en `CodeDeployDeploymentGroup`:
- `DeploymentConfigName: CodeDeployDefault.ECSAllAtOnce` → switch inmediato (sin canary)
- `ActionOnTimeout: CONTINUE_DEPLOYMENT` → automático, sin aprobación manual
- `TerminationWaitTimeInMinutes: 5` → mantiene Blue disponible 5 min por si hay rollback

---

## Seguridad de red

```
Internet
   │ :80
   ▼
ALBSecurityGroup (0.0.0.0/0 → port 80)
   │
   ▼
ContainerSecurityGroup (solo desde ALBSecurityGroup → port 80)
   │
   ▼
Fargate Tasks (10.0.x.x)
```

Los contenedores no reciben tráfico directo de internet — solo a través del ALB.

---

## Estructura del proyecto

```
aws-cdi-cd-pipeline/
├── apps/
│   └── api/
│       ├── app.py           ← Flask app (modifica aquí tu código)
│       ├── Dockerfile
│       └── requirements.txt
│
├── infrastructure/
│   └── cloudformation/
│       ├── stack.yml        ← Infraestructura base (desplegar primero)
│       └── pipeline.yml     ← CI/CD (desplegar segundo)
│
└── docs/
    ├── README.md            ← Este documento (arquitectura)
    └── QUICKSTART.md        ← Referencia rápida de comandos
```

---

Para el setup completo consulta el [README raíz](../README.md).
