#!/usr/bin/env bash

#Váriavel do tipo do servidor
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
echo "Protocolo: $idchamado" | tee -a webdecisor.log


echo ""
echo ""
echo -n "Digite uma senha MUITO FORTE para o usuário webdecisor:"
read password

source /etc/wildfly.conf

PG_DATA=$(ps aux | grep -oP '^postgres .*postmaster.*-D *\K.*')
PG_VERSION=$(cat $PG_DATA/PG_VERSION)


CreateRole="CREATE ROLE webdecisor login password '$password' nosuperuser inherit nocreatedb nocreaterole connection limit 5;"

GrantPermissions="GRANT USAGE ON SCHEMA integracao_webdecisor TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaocliente  TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaoproduto TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaoidentificador TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaogrupo TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaotipo TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaofabricante TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaovendedor TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaofornecedor TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaoinformacoesvenda TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaovenda TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaocompra TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaonotasfiscais TO webdecisor;
GRANT SELECT ON integracao_webdecisor.v_extracaoestoque TO webdecisor;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO webdecisor;"

QueryTeste="SELECT * FROM unidadenegocio LIMIT 1;
SELECT * FROM integracao_webdecisor.v_extracaogrupo limit 1;"

RevokeDrop="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from webdecisor;
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA integracao_webdecisor from webdecisor;
REVOKE ALL PRIVILEGES ON SCHEMA integracao_webdecisor from webdecisor;
DROP ROLE IF EXISTS webdecisor;"


echo "Removendo a ROLE webdecisor se existir"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$RevokeDrop"

echo " "

echo "Criando ROLE webdecisor"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$CreateRole"

echo " "

echo "Dando as devidas pemissões para a ROLE webdecisor"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$GrantPermissions"


 if [[ "$PG_VERSION" == "14" ]]; then
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/webdecisor/d' pg_hba.conf
	echo "host	all		webdecisor	samenet			scram-sha-256" >> pg_hba.conf
	echo ""
	echo
	echo ""
   
 else
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/webdecisor/d' pg_hba.conf
	echo "host	all		webdecisor	samenet			md5" >> pg_hba.conf
	echo ""
	echo
	echo ""
 fi			

service postgresql-$PG_VERSION reload

psql -X -h $END_SERVIDOR -U "webdecisor" -d $CHINCHILA_DS_DATABASENAME --password --command="$QueryTeste"

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
echo "Acesso para WebDecisor"
echo " "
echo "USUÁRIO: webdecisor"
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
	sed -i '/webdecisor/d' pg_hba.conf
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
