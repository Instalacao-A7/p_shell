#!/usr/bin/env bash

#Variável do tipo do servidor
TipoServidor=`hostname | cut -b 1-9`

echo "########################################################"
echo " 		    Iniciando Procedimentos                   "
echo "########################################################"

echo -n "Senha do usuário postgres: "
read -s PGPASSWORD
echo
export PGPASSWORD

echo -n "Digite ID chamado: "
read idchamado
echo "Protocolo: $idchamado" | tee -a nappsolutions.log


echo ""
echo ""
echo -n "Digite uma senha MUITO FORTE para o usuário nappsolutions:"
read password

source /etc/wildfly.conf

PG_DATA=$(ps aux | grep -oP '^postgres .*postmaster.*-D *\K.*')
PG_VERSION=$(cat $PG_DATA/PG_VERSION)


DropRole="DROP ROLE IF EXISTS nappsolutions;"

CreateRole="CREATE ROLE nappsolutions login password '$password' nosuperuser inherit nocreatedb nocreaterole connection limit 5;"

GrantPermissions="GRANT USAGE ON SCHEMA integracao_napp_solutions TO nappsolutions;
GRANT SELECT ON integracao_napp_solutions.v_dadosvenda TO nappsolutions;
GRANT SELECT ON integracao_napp_solutions.v_itensvenda TO nappsolutions;
GRANT SELECT ON integracao_napp_solutions.v_catalogo TO nappsolutions;
GRANT SELECT ON integracao_napp_solutions.v_unidadesnegocio TO nappsolutions;
GRANT SELECT ON integracao_napp_solutions.v_estoque TO nappsolutions;
GRANT SELECT ON integracao_napp_solutions.v_promocao TO nappsolutions;"

QueryTeste="SELECT * FROM integracao_napp_solutions.v_unidadesnegocio limit 1;"

RevokeDrop="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA integracao_napp_solutions from nappsolutions;
REVOKE ALL PRIVILEGES ON SCHEMA integracao_napp_solutions from nappsolutions;
DROP ROLE IF EXISTS nappsolutions;"


echo "Removendo a ROLE nappsolutions se existir"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$RevokeDrop"

echo " "

echo "Criando ROLE nappsolutions"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$CreateRole"

echo " "

echo "Dando as devidas pemissões para a ROLE nappsolutions"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$GrantPermissions"


 if [[ "$PG_VERSION" == "14" ]]; then
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/nappsolutions/d' pg_hba.conf
	echo "host	all		nappsolutions	samenet			scram-sha-256" >> pg_hba.conf
	echo ""
	echo
	echo ""
   
 else
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/nappsolutions/d' pg_hba.conf
	echo "host	all		nappsolutions	samenet			md5" >> pg_hba.conf
	echo ""
	echo
	echo ""
 fi			

service postgresql-$PG_VERSION reload

psql -X -h $END_SERVIDOR -U "nappsolutions" -d $CHINCHILA_DS_DATABASENAME --password --command="$QueryTeste"

if [ $TipoServidor == "localhost" ]; then
        echo "#######################################################"
        echo ""
        echo "O servidor dessa loja é físico, não é necessário "
        echo "realizar a liberação do firewall."
        echo "#######################################################"
else
        echo "#######################################################"
        echo ""
        echo "O servidor dessa loja é em nuvem, seguir os passos do  "
        echo " 	  KB http://kb.a7.net.br/index.php?curid=9470"
        echo "#######################################################"
		echo ""
        # Captura o IP externo da rede usando curl ifconfig.me
        END_SERVIDOR=$(curl -s --connect-timeout 30 ifconfig.me)
        if [ -z "$END_SERVIDOR" ]; then
    		echo -e "\e[31mFalha ao obter o IP externo: conexão expirou ou serviço indisponível.\e[0m"
			echo -e "\e[31mObtenha o IP EXTERNO manualmente para substituir nas credenciais.\e[0m"
    		# Você pode definir um valor padrão ou tomar outras ações, se necessário
		else
    		echo "IP externo identificado: $END_SERVIDOR"
		fi
        
        echo ""
        echo "Aguardando 10 segundos para prosseguir automaticamente..."
		sleep 10
fi

echo " "
echo "########################################################"
echo "Acesso para NAPP SOLUTIONS"
echo " "
echo "USUÁRIO: nappsolutions"
echo "SENHA: $password"
echo "HOST: $END_SERVIDOR"
echo "DATABASE: $CHINCHILA_DS_DATABASENAME" 
echo "SGBD: PostgreSQL"
echo "PORTA: 5432"
echo "PROTOCOLO: $idchamado"
echo ""
echo "#########################################################"
echo ""


echo " Desfazer a liberação?"

echo -n " digite a opção: [s/n]: "
read CONFIRMACAO

echo

 if [[ "$CONFIRMACAO" == "s" ]]; then
	echo "Desfazendo liberação ..."
	echo ""
	psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$RevokeDrop"
	echo
	echo ""
	sed -i '/nappsolutions/d' pg_hba.conf
	echo ""
	echo ""
	service postgresql-$PG_VERSION reload
	echo""
	echo "Concluído."
	echo ""
	
 else	
	echo ""
	echo ""
	echo ""
	echo "#######################################################"
	echo "                         OK                            "
	echo "Copie os 'Dados de acesso' e encaminhe ao solicitante. "
	echo "#######################################################"
 fi
