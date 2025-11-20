En el siguiente documento se explicaran los pasos a seguir para esta parte de la práctica
# 🧩 Práctica Final – GitOps con Terraform, Ansible y GitHub Actions

Este repositorio contiene la solución a la **Práctica Final del módulo de GitOps / IaC**, cuyo objetivo es desplegar una arquitectura altamente disponible en AWS utilizando **Terraform**, **Ansible** y un pipeline de **CI/CD con GitHub Actions**.

La infraestructura se construye siguiendo principios GitOps: todo el ciclo (validación, provisión y configuración) se ejecuta automáticamente desde GitHub.

---

## 🚀 Arquitectura implementada

La solución implementa una arquitectura de alta disponibilidad en AWS compuesta por:

### 🏗️ Componentes principales
- **VPC** con subredes públicas y privadas distribuidas entre múltiples AZs.
- **Application Load Balancer (ALB)** para distribuir tráfico HTTP/HTTPS.
- **Auto Scaling Group (ASG)** con:
  - *Mínimo:* 2 instancias EC2  
  - *Máximo:* 4 instancias  
  - Distribuidas en AZs distintas.
- **Instancias EC2** en **subredes públicas**, configuradas mediante **Ansible**.
- **RDS PostgreSQL** en una **subred privada**.
- **NAT Gateway** para permitir actualizaciones de la base de datos.

---

## 🔐 Security Groups

| Recurso | Reglas |
|--------|--------|
| **EC2 (ASG)** | Entradas: 80/443 desde SG del ALB · 22 desde 0.0.0.0/0 |
| **ALB** | Entradas: 80/443 desde Internet |
| **RDS PostgreSQL** | Entrada 5432 solo desde SG de las EC2 |

---

## 📦 Tecnologías utilizadas

- **Terraform** — Provisiona la infraestructura AWS.
- **Ansible** — Configura las instancias EC2.
- **GitHub Actions** — Automatiza validación, despliegue y configuración.
- **AWS (EC2, RDS, ALB, VPC, NAT Gateway)**

---

## 🔄 Flujo GitOps / CI-CD

El repositorio incluye un workflow de GitHub Actions que:

1. **Valida** sintaxis de Terraform y Ansible.
2. **Ejecuta Terraform plan/apply** para crear la infraestructura.
3. **Ejecuta Ansible** para configurar las máquinas creadas.
4. Se ejecuta **manualmente** mediante `workflow_dispatch`.

---

## 🔑 Secretos requeridos en GitHub

Configurar en **Settings → Secrets and variables → Actions**:

| Secreto | Descripción |
|---------|-------------|
| `AWS_ACCESS_KEY_ID` | Credenciales de acceso a AWS |
| `AWS_SECRET_ACCESS_KEY` | Credenciales de acceso a AWS |
| `AWS_REGION` | Región donde se desplegará la infra |
| `EC2_SSH_PRIVATE_KEY` | Llave privada para que Ansible acceda a las EC2 |

---

## 📁 Estructura del repositorio (propuesta)

.
├── terraform/
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ ├── networking/
│ ├── compute/
│ └── rds/
├── ansible/
│ ├── inventories/
│ ├── roles/
│ └── playbook.yml
├── .github/
│ └── workflows/
│ └── gitops-pipeline.yml
└── README.md
---

## ▶️ Ejecución del pipeline

1. Configura los secretos en GitHub.
2. Ve a **Actions** → selecciona el workflow `gitops-pipeline`.
3. Haz clic en **Run workflow**.

Esto ejecutará:

- Validación de Terraform y Ansible  
- Creación de infraestructura  
- Configuración mediante Ansible  

---

## 💡 Notas finales

- Las instancias EC2 y la base de datos RDS utilizan el tamaño **t3.micro** aunque según el enunciado era small, esto obliga a pagos.
- La infraestructura es completamente reproducible y destruible con `terraform destroy`.

---



Solo dímelo 😊

