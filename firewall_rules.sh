#!/bin/bash

# =================================================================
# SCRIPT DE CONFIGURACIÓN DE IPTABLES REUTILIZABLE
# =================================================================

echo "Limpiando reglas de firewall existentes..."
iptables -F
iptables -X
iptables -Z

# -----------------------------------------------------------------
# Políticas por Defecto: BLOQUEAR TODO (DROP)
# -----------------------------------------------------------------
echo "Estableciendo políticas por defecto en DROP..."
iptables -P INPUT   DROP
iptables -P OUTPUT  DROP
iptables -P FORWARD DROP

# -----------------------------------------------------------------
# Variables de Red (Centralizadas para fácil reutilización)
# -----------------------------------------------------------------
# --- Redes Internas
INTERNAL_NET_INFRA="192.168.1.0/27"
INTERNAL_NET_USERS="192.168.1.32/27"

# --- Hosts y Servidores
TI_PC1="192.168.1.6"
TI_PC2="192.168.1.7"
SRV_DEV="192.168.1.10"
SRV_WEB="192.168.1.11"
SRV_PROD="192.168.1.12"
SRV_HOSTING="192.168.1.13"

# -----------------------------------------------------------------
# Reglas Fundamentales (Loopback y Conexiones Establecidas)
# -----------------------------------------------------------------
echo "Aplicando reglas fundamentales..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# =================================================================
# REGLAS DE ENTRADA (INPUT - Tráfico HACIA el servidor firewall)
# =================================================================
echo "Configurando reglas de ENTRADA (INPUT)..."

# --- Acceso a Nagios solo desde T.I. (puertos 80/http y 443/https)
iptables -A INPUT -p tcp -s $TI_PC1 --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -s $TI_PC1 --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -s $TI_PC2 --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -s $TI_PC2 --dport 443 -j ACCEPT

# --- Aceptar SSH solo desde IPs/redes autorizadas (puerto 22)
iptables -A INPUT -p tcp -s 192.168.23.0/24 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -s 200.27.0.0/24 --dport 22 -j ACCEPT
iptables -A INPUT -p tcp -s 146.83.1.0/24 --dport 22 -j ACCEPT

# =================================================================
# REGLAS DE REENVÍO (FORWARD - Tráfico que PASA A TRAVÉS del servidor)
# =================================================================
echo "Configurando reglas de REENVÍO (FORWARD)..."

# --- Acceso web a Servidor de Hosting y Web Corporativo desde cualquier lugar
iptables -A FORWARD -p tcp -d $SRV_WEB --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp -d $SRV_WEB --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp -d $SRV_HOSTING --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp -d $SRV_HOSTING --dport 443 -j ACCEPT

# --- Acceso a Servidores Internos (Dev y Prod) SÓLO desde redes internas
# Nota: La regla para SRV_DEV solo tendrá efecto si este script se ejecuta
# en un firewall que NO sea 192.168.1.10.
iptables -A FORWARD -s $INTERNAL_NET_INFRA -d $SRV_DEV -j ACCEPT
iptables -A FORWARD -s $INTERNAL_NET_USERS -d $SRV_DEV -j ACCEPT
iptables -A FORWARD -s $INTERNAL_NET_INFRA -d $SRV_PROD -j ACCEPT
iptables -A FORWARD -s $INTERNAL_NET_USERS -d $SRV_PROD -j ACCEPT

# =================================================================
# REGLAS DE SALIDA (OUTPUT - Tráfico que ORIGINA el servidor firewall)
# =================================================================
echo "Configurando reglas de SALIDA (OUTPUT)..."

# --- Permitir SSH saliente hacia las redes autorizadas
iptables -A OUTPUT -p tcp -d 192.168.23.0/24 --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp -d 200.27.0.0/24 --dport 22 -j ACCEPT
iptables -A OUTPUT -p tcp -d 146.83.1.0/24 --dport 22 -j ACCEPT
# --- Reglas adicionales para el funcionamiento del servidor
# Permitir consultas DNS (necesario para resolver nombres de dominio para actualizaciones, etc.)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Permitir que Nagios realice sus checks a toda la red interna
iptables -A OUTPUT -d $INTERNAL_NET_INFRA -j ACCEPT
iptables -A OUTPUT -d $INTERNAL_NET_USERS -j ACCEPT

echo "Firewall configurado exitosamente."
