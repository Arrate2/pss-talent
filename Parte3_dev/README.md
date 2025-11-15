En el siguiente documento se explicaran los pasos a seguir para esta parte de la práctica

# Proyecto -- Parte 3: DevOps / Automatización

Este repositorio contiene la parte 3 del proyecto orientado a DevOps y
automatización. En esta fase se despliega una infraestructura completa
para alojar una aplicación web utilizando Terraform y Ansible, todo
gestionado mediante un script de automatización.

## 📁 Estructura del repositorio

    Parte3_dev/
    ├── terraform/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── ...
    ├── ansible/
    │   ├── ansible.cfg
    │   ├── site.yml
    │   ├── inventory_aws_ec2.yml (si aplica)
    │   ├── roles/
    │   │   ├── webserver/
    │   │   │   ├── tasks/
    │   │   │   ├── templates/
    │   │   │   └── ...
    │   │   └── database/
    │   │       ├── tasks/
    │   │       └── ...
    ├── deploy.sh
    └── README.md

## 🚀 Flujo de despliegue

1.  **Terraform** crea la infraestructura en AWS:
    -   VPC personalizada\
    -   Subredes públicas\
    -   EC2 web y EC2 base de datos\
    -   Security groups\
2.  `deploy.sh` ejecuta Terraform y espera a que los recursos estén
    disponibles.\
3.  **Ansible** configura la infraestructura:
    -   Rol `webserver`: Apache/PHP + WordPress\
    -   Rol `database`: instalación y configuración de MariaDB/MySQL\
4.  La aplicación queda operativa automáticamente.

## 📌 Prerrequisitos

-   AWS CLI configurado (`aws configure`)

-   Terraform ≥ 1.0

-   Ansible ≥ 2.15

-   Python 3 + módulos:

        pip install boto3 botocore

-   Clave SSH configurada para acceder a las máquinas creadas

## ▶️ Cómo ejecutar el despliegue

Ejecutar desde la carpeta raíz del proyecto:

``` bash
chmod +x deploy.sh
./deploy.sh
```

Este script hará:

1.  `terraform init`
2.  `terraform apply --auto-approve`
3.  Espera a que las instancias estén listas
4.  `ansible-playbook ansible/site.yml` usando el inventario dinámico o
    estático configurado

## ⚙️ Personalización

-   Editar variables en `terraform/variables.tf`

-   Ajustar plantilla WordPress en:

        ansible/roles/webserver/templates/wp-config.php.j2

-   Configurar credenciales DB en:

        ansible/roles/database/tasks/

## 🧹 Destruir la infraestructura

Para eliminar todos los recursos:

``` bash
cd terraform
terraform destroy --auto-approve
```

## 📚 Mejoras posibles
No están realizadas

-   Validaciones post-deploy con Ansible (HTTP 200)
-   Pipeline CI/CD
-   Monitoreo con CloudWatch o Prometheus
-   Balanceador de carga y autoescalado

