#!/usr/bin/env bash

# Variavel para o Tipo do servidor
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
echo "Protocolo: $idchamado" | tee -a farlog.log


echo ""
echo ""
echo -n "Digite uma senha MUITO FORTE para o usuário farlog:"
read password

source /etc/wildfly.conf

PG_DATA=$(ps aux | grep -oP '^postgres .*postmaster.*-D *\K.*')
PG_VERSION=$(cat $PG_DATA/PG_VERSION)


DropRole="DROP ROLE IF EXISTS farlog;"

CreateRole="CREATE ROLE farlog login password '$password' nosuperuser inherit nocreatedb nocreaterole connection limit 5;"

GrantPermissions="GRANT USAGE ON SCHEMA integracao_farlog TO farlog;
GRANT SELECT ON integracao_farlog.v_vendas_entregas TO farlog;"

QueryTeste="SELECT * FROM integracao_farlog.v_vendas_entregas limit 1;"

RevokeDrop="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA integracao_farlog from farlog;
REVOKE ALL PRIVILEGES ON SCHEMA integracao_farlog from farlog;
DROP ROLE IF EXISTS farlog;"


echo "Removendo a ROLE farlog se existir"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$RevokeDrop"

echo " "

echo "Criando ROLE farlog"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$CreateRole"

echo " "

echo "Dando as devidas pemissões para a ROLE farlog"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$GrantPermissions"


 if [[ "$PG_VERSION" == "14" ]]; then
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/farlog/d' pg_hba.conf
	echo "host	all		farlog	samenet			scram-sha-256" >> pg_hba.conf
	echo ""
	echo
	echo ""
   
 else
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/farlog/d' pg_hba.conf
	echo "host	all		farlog	samenet			md5" >> pg_hba.conf
	echo ""
	echo
	echo ""
 fi			

service postgresql-$PG_VERSION reload

psql -X -h $END_SERVIDOR -U "farlog" -d $CHINCHILA_DS_DATABASENAME --password --command="$QueryTeste"

#Verificação se o servidor é físico ou em nuvem
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
	echo Pressione qualquer tecla para prosseguir!	
	read ciente
 

fi

echo " "
echo "########################################################"
echo "Acesso para Farlog"
echo " "
echo "Usuário: farlog"
echo "Senha: $password"
echo "IP do Servidor: $END_SERVIDOR"
echo "Nome da base: $CHINCHILA_DS_DATABASENAME" 
echo "Protocolo: $idchamado"
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
	sed -i '/farlog/d' pg_hba.conf
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
