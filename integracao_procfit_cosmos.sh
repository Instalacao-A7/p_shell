#!/usr/bin/env bash

# Variável de exemplo
TipoServidor=`hostname | cut -b 1-9`

echo "########################################################"
echo " 		    Iniciando Procedimentos                   "
echo "########################################################"

echo -n "Senha do usuário postgres: "
read -s PGPASSWORD
echo
export PGPASSWORD

echo -n "Digite o código do chamado - GLPI: "
read idchamado
echo "Protocolo: $idchamado" | tee -a procfit_cosmos.log


echo ""
echo ""
echo -n "Digite uma senha MUITO FORTE para o usuário procfit:"
read password

source /etc/wildfly.conf

PG_DATA=$(ps aux | grep -oP '^postgres .*postmaster.*-D *\K.*')
PG_VERSION=$(cat $PG_DATA/PG_VERSION)

DropRole="DROP ROLE IF EXISTS integracao_procfit_cosmos;"

CreateRole="CREATE ROLE integracao_procfit_cosmos login password '$password' nosuperuser inherit nocreatedb nocreaterole connection limit 5;"

GrantPermissions="GRANT USAGE  ON SCHEMA integracao_procfit_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_compras TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_estoque TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_filiais TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_medicos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_pedidos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_vendas TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_vendas_finalizadoras TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_clientes TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.marcas_produtos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.produtos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.produtos_ean TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.secoes_produtos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_compras_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_estoque_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_vendas_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_vendas_finalizadoras_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.cfe_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.nfe_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.produtos_classificacoes_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.produtos_cosmos TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_vendas_prescricao TO integracao_procfit_cosmos;
GRANT SELECT ON integracao_procfit_cosmos.bi_vendas_documento_fiscal TO integracao_procfit_cosmos;"

QueryTeste="SELECT * FROM integracao_procfit_cosmos.bi_filiais limit 1;"

RevokeDrop="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA integracao_procfit_cosmos from integracao_procfit_cosmos;
REVOKE ALL PRIVILEGES ON SCHEMA integracao_procfit_cosmos from integracao_procfit_cosmos;
DROP ROLE IF EXISTS integracao_procfit_cosmos;"


echo "Removendo a ROLE integracao_procfit_cosmos se existir"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$RevokeDrop"

echo " "

echo "Criando ROLE integracao_procfit_cosmos"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$CreateRole"

echo " "

echo "Dando as devidas pemissões para a ROLE integracao_procfit_cosmos"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$GrantPermissions"


 if [[ "$PG_VERSION" == "14" ]]; then
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/integracao_procfit_cosmos/d' pg_hba.conf
	echo "host	all		integracao_procfit_cosmos	samenet			scram-sha-256" >> pg_hba.conf
	echo ""
	echo
	echo ""
   
 else
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/integracao_procfit_cosmos/d' pg_hba.conf
	echo "host	all		integracao_procfit_cosmos	samenet			md5" >> pg_hba.conf
	echo ""
	echo
	echo ""
 fi			

service postgresql-$PG_VERSION reload

psql -X -h $END_SERVIDOR -U "integracao_procfit_cosmos" -d $CHINCHILA_DS_DATABASENAME --password --command="$QueryTeste"


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



echo ""
echo "#########################################################"
echo "Acesso para PROCFIT_COSMOS"
echo ""
echo "USUÁRIO: integracao_procfit_cosmos"
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
	sed -i '/integracao_procfit_cosmos/d' pg_hba.conf
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
