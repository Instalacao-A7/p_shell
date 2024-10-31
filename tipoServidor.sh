#!/usr/bin/env bash

PGPASSWORD=$1

#echo -n "Senha do usuário postgres: "
#read -s PGPASSWORD
#echo
#export PGPASSWORD

source /etc/wildfly.conf

query="\copy (select * from configuracaoavancadaunidadenegocio where chave = 'Geral.tipoServidorUnidadeNegocio' and unidadenegocioid = (select unidadenegocioid from unidadenegocioservidor)) to '/home/alpha7/codunidade.txt';"

psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$query"


server=`cat codunidade.txt | cut -d "." -f 2 | cut -d "c" -f 2 | cut -d "o" -f 2 | cut -d "N" -f 1`
ram=`free -h | head -n 2 |tail -n 1 |cut -d ":" -f2 | cut -d "G" -f1`

########## Variaveis de conversão ##########

ramInt=${ram%,*}

testeRAM=`if [ "$server" == "	CE" ]; then
	if [ $ramInt -lt 14 ]; then
		echo -e "** Servidor ESC, Ram fora dos requisitos **"
		echo ""
        	echo "RAM Instalada: $ram GB"
	else
		echo "** Servidor ESC, Ram dentro dos requisitos **"
		echo ""
		echo "RAM Instalada: $ram GB"
	fi
else
	if [ $ramInt -lt 7 ]; then
        	echo -e "** Servidor Loja/Unico, Ram fora dos requisitos **"
		echo ""
        	echo "RAM Instalada: $ram GB"
	else
        	echo "** Servidor Loja/Unico, Ram dentro dos requisitos **"
		echo ""
        	echo "RAM Instalada $ram GB"
	fi
fi`

rm -rf codunidade.txt
