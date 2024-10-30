#!/usr/bin/env bash
# Exemplo de estrutura if no Shell script

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
echo "Protocolo: $idchamado" | tee -a leitura_bd.log

echo -n "Digitar o usuário: "
read  user

echo -n "Digite uma senha MUITO FORTE para o usuário: "
read  password
echo ""
echo ""


source /etc/wildfly.conf

PG_DATA=$(ps aux | grep -oP '^postgres .*postmaster.*-D *\K.*')
PG_VERSION=$(cat $PG_DATA/PG_VERSION)


CreateRole="CREATE ROLE $user login password '$password' nosuperuser inherit nocreatedb nocreaterole connection limit 5;"

GrantPermissions="GRANT SELECT ON ALL TABLES IN SCHEMA public TO $user;"

QueryTeste="SELECT * FROM unidadenegocio LIMIT 1;"

RevokeDrop="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from $user;
DROP ROLE IF EXISTS $user;"


echo "Removendo a ROLE $user se existir"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$RevokeDrop"

echo " "

echo "Criando ROLE $user"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$CreateRole"

echo " "

echo "Dando as devidas pemissões para a ROLE $user"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$GrantPermissions"


 if [[ "$PG_VERSION" == "14" ]]; then
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i "/$user/d" pg_hba.conf
	echo "host	all		$user	samenet			scram-sha-256" >> pg_hba.conf
	echo ""
	echo
	echo ""
   
 else
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i "/$user/d" pg_hba.conf
	echo "host	all		$user	samenet			md5" >> pg_hba.conf
	echo ""
	echo
	echo ""
 fi			

service postgresql-$PG_VERSION reload

psql -X -h $END_SERVIDOR -U "$user" -d $CHINCHILA_DS_DATABASENAME --password --command="$QueryTeste"

#/ Condição no if
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
echo "#########################################################"
echo " "
echo "USUÁRIO: $user"
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
	sed -i "/$user/d" pg_hba.conf
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
	echo ""
	echo ""
 fi
