#!/bin/bash

# --- Configuración y Variables ---
TERRAFORM_DIR="terraform"
ANSIBLE_INVENTORY="ansible/aws_ec2.yml"
ANSIBLE_PLAYBOOK="ansible/site.yml"
export ANSIBLE_CONFIG="./ansible/ansible.cfg"

echo "========================================================"
echo "         🚀 INICIANDO DESPLIEGUE AUTOMÁTICO DE WORDPRESS"
echo "========================================================"

# 1. Runs terraform apply –auto-approve [cite: 49]
echo -e "\n--- FASE 1: PROVISIONAMIENTO DE INFRAESTRUCTURA (Terraform) ---"
cd $TERRAFORM_DIR
terraform init
terraform apply -auto-approve

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Terraform apply falló. Deteniendo el despliegue."
    exit 1
fi
cd .. # Volver al directorio raíz

echo -e "\n--- DANDO MARGEN DE 45 SEGUNDOS PARA LA INICIALIZACIÓN SSH ---"
sleep 45

# 2. Waits until the EC2 instances are created and available [cite: 50]
echo -e "\n--- FASE 2: ESPERANDO CONEXIÓN SSH ---"
# Espera activa hasta que ambas instancias sean accesibles vía SSH (usuario ubuntu)
ansible all -i $ANSIBLE_INVENTORY -m wait_for_connection -e "ansible_user=ubuntu"
if [ $? -ne 0 ]; then
    echo "❌ ERROR: No se pudo establecer conexión SSH con las instancias. Verifique el Key Pair y los Security Groups."
    exit 1
fi

# 3. Runs ansible-playbook site.yml using the dynamic inventory [cite: 51]
echo -e "\n--- FASE 3: CONFIGURACIÓN DE WORDPRESS (Ansible) ---"
ansible-playbook -i $ANSIBLE_INVENTORY $ANSIBLE_PLAYBOOK

if [ $? -ne 0 ]; then
    echo "❌ ERROR: El playbook de Ansible falló durante la configuración."
    exit 1
fi

# --- Finalización y Resultado ---
WEB_IP=$(terraform output -raw -state=$TERRAFORM_DIR/terraform.tfstate webserver_public_ip)

echo -e "\n========================================================"
echo "         ✅ DESPLIEGUE COMPLETO Y CONFIGURADO CON ÉXITO"
echo "========================================================"
echo "URL de WordPress (Acceso Público): http://$WEB_IP"
echo "¡El proceso completo se ejecutó con un solo comando!"
echo "========================================================"
