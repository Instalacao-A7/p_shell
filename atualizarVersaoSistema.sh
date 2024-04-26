#!/bin/bash

WILDFLY_STANDALONE=/usr/wildfly/standalone
CHINCHILA_CLIENT_DIR=$WILDFLY_STANDALONE/chinchila-client
CHINCHILA_PDV_DIR=$WILDFLY_STANDALONE/chinchila-pdv
CHINCHILA_BROKER_DIR=$WILDFLY_STANDALONE/chinchila-broker
CHINCHILA_UPDATE_PGKS_DIR=$WILDFLY_STANDALONE/chinchila-update-pkgs
DEPLOYMENTS_DIR=$WILDFLY_STANDALONE/deployments

# Function to display message in cyan color
function msg(){
  echo -e "\e[36;1m$1\e[0m"
}

# Function to display error message in red color
function error(){
  echo -e "\e[31;1m$1\e[0m"
}

# Function to display warning message in yellow color
function warn(){
  echo -e "\e[33;1m$1\e[0m"
}

if [ $UID -eq 0 ]; then
  error "NÃO executar como root!"
  exit 1
fi

# Asking for the link to the package
msg "Insira o link do pacote de atualização:"
read -p "Link: " package_link

# Downloading the package
msg "Baixando pacote de atualização..."
wget -c "$package_link" -P "$CHINCHILA_UPDATE_PGKS_DIR" || {
  error "Falha ao baixar o pacote. Verifique o link e se há conectividade com a internet."
  exit 1
}

PACOTE="$CHINCHILA_UPDATE_PGKS_DIR/$(basename "$package_link")"

# Update the system
msg "Atualizando o sistema com o pacote baixado..."
sudo service wildfly stop || {
  error "Falha ao parar o serviço WildFly. Certifique-se de ter as permissões adequadas."
  exit 1
}

# Applying the update script
wget -q "http://a7.net.br/scherrer/aplicarAtualizacao.sh" && bash "aplicarAtualizacao.sh" "$PACOTE" || {
  error "Falha ao aplicar a atualização. Verifique se o script de atualização está acessível e se a execução é permitida."
  exit 1
}

# Starting the WildFly service
sudo service wildfly start || {
  error "Falha ao iniciar o serviço WildFly. Certifique-se de ter as permissões adequadas."
  exit 1
}

msg "Sistema atualizado com sucesso!"
