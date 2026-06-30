# 🚀 Quick Start - AWS Pipeline en 10 Pasos

## Resumen rápido (30 minutos)

### Paso 1-2: Crear ECR
```
AWS Console → ECR → Create Repository
Nombre: mi-app-repo
Copia la URI: 123456789012.dkr.ecr.us-east-1.amazonaws.com/mi-app-repo
```

### Paso 3-5: Crear ECS
```
AWS Console → ECS
1. Crear Cluster: mi-cluster-ecs (Fargate)
2. Crear Task Definition: mi-task-def
   - Contenedor: mi-contenedor-app
   - Imagen: [TU_ECR_URI]:latest
   - Puerto: 80
3. Crear Service: mi-servicio-ecs
   - IP Pública: ✓ Activada
```

### Paso 6: IAM Permissions
```
AWS Console → IAM → Roles
Busca: codebuild-*-service-role
Adjunta: AmazonEC2ContainerRegistryPowerUser
```

### Paso 7-9: Crear Pipeline
```
AWS Console → CodePipeline → Create
Nombre: mi-pipeline-github

SOURCE:
- GitHub (GitHub App)
- Repo: tu-repo
- Rama: main
- Webhooks: ✓

BUILD:
- CodeBuild (crear nuevo proyecto)
- Privilegios Personalizados: ✓ ACTIVAR
- Variables:
  AWS_ACCOUNT_ID=123456789012
  AWS_DEFAULT_REGION=us-east-1
  IMAGE_REPO_NAME=mi-app-repo

DEPLOY:
- ECS
- Cluster: mi-cluster-ecs
- Service: mi-servicio-ecs
- Archivo: imagedefinitions.json
```

### Paso 10: Push a GitHub
```bash
git add .
git commit -m "AWS pipeline setup"
git push origin main
```

**¡Listo! El pipeline se ejecutará automáticamente.**

---

## Validación Rápida

1. Ve a **CodePipeline** → Verifica que está en "Succeeded"
2. Ve a **ECS** → Tu servicio → Obtén la IP pública
3. Abre: `http://TU_IP_PUBLICA`
4. Deberías ver: `{"status": "healthy", "message": "..."}`

---

## Variables Críticas (NO OLVIDES)

| Variable | Ejemplo | Dónde obtenerla |
|----------|---------|-----------------|
| AWS_ACCOUNT_ID | 123456789012 | AWS Console → Cuenta |
| AWS_DEFAULT_REGION | us-east-1 | Tu región |
| IMAGE_REPO_NAME | mi-app-repo | ECR Repository |
| Contenedor en Task Def | mi-contenedor-app | Debe coincidir con buildspec.yml |

---

## Errores Comunes

| Error | Solución |
|-------|----------|
| Docker-in-Docker failed | Activa "Privilegios Personalizados" en CodeBuild |
| Access denied to ECR | Adjunta `AmazonEC2ContainerRegistryPowerUser` al rol |
| La tarea no inicia | Verifica nombre del contenedor = `mi-contenedor-app` |
| Webhook no funciona | GitHub App instalada + rama = `main` |

---

## Archivos del Proyecto

- **buildspec.yml**: Motor que CodeBuild ejecuta
- **Dockerfile**: Empaqueta tu app
- **app.py**: Aplicación Flask (cambiar según necesites)
- **requirements.txt**: Dependencias Python
- **.env.example**: Variables de configuración

---

**¿Necesitas ayuda?** Revisa el README.md completo para troubleshooting detallado.
