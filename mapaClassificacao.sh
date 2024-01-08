#!/usr/bin/env bash

########## Consulta no banco ##########

PGPASSWORD=$1

source /etc/wildfly.conf

psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME -c "\copy (select nome, caminho from classificacao where (principal = 'true') or (folha = true and principal = true) order by caminho) to '/home/alpha7/shared/mapaClassificacao.xlsx'"
