# Suggestion: cloud-platform

## Evidencia encontrada en el proyecto

- Restricción de proveedor cloud en constitución: Azure obligatorio (`.boltf/memory/constitution.md`).
- Pipeline de validación de infraestructura en `.github/workflows/infra-validation.yml`.
- Automatización de CI/CD e infraestructura en `.github/agents/bolt-cicd.agent.md`.
- Plantilla de guía de despliegue en `.boltf/docs/templates/deployment-guide-template.md`.

## Sugerencia de contenido para este scope

- Gobernanza cloud basada en Azure-first (entornos, seguridad, compliance).
- Estructuras y convenciones IaC (Bicep/Terraform/Pulumi) por entorno.
- Estándares de despliegue y rollback para dev/uat/pre/prod.
- Integración de validaciones de infraestructura en CI/CD.

## Fuentes

- `.boltf/memory/constitution.md`
- `.github/workflows/infra-validation.yml`
- `.github/agents/bolt-cicd.agent.md`
- `.boltf/docs/templates/deployment-guide-template.md`
