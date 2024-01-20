#!/usr/bin/env bash

#Variávies:
ram=`free -h | head -n 2 |tail -n 1 |cut -b 15-16`

cpu=`lshw -c cpu | head -n 2 | tail -n 1 | cut -c 17-`

disk=`sudo fdisk -l | grep -i "disk /dev"`

veros=`cat /etc/redhat-release`

parSda=`sudo fdisk -l | grep -i "disk /dev" | head -n 1 | tail -n 1 | cut -d ":" -f 2 | cut -d "." -f 1`

parRoot=`sudo fdisk -l | grep -i "root" | head -n 1 | tail -n 1 | cut -d ":" -f 2 | cut -d "." -f 1`

parSwp=`sudo fdisk -l | grep -i "swap" | head -n 1 | tail -n 1 | cut -d ":" -f 2 | cut -d "M" -f 1`

versionOs=`cat /etc/redhat-release | cut -b 22-24`

erroMemoria=`cd /usr/wildfly/bin && ls | grep "hs_err" | head -n 1 | tail -n 1 | cut -b 1-15`


#Impressão no terminal:
echo "-------------------------------------- Memoria RAM ------------------------------------"
echo ""
if [ $ram -lt 7 ]; then
        echo -e "** RAM abaixo dos requisitos **"
        echo "RAM Instalada: $ram GB"
else
        echo "** RAM dentro dos requisitos **"
        echo "RAM Instalada $ram GB"
fi
echo ""
echo "---------------------------------------------------------------------------------------"
echo ""
echo "----------------------------------------- CPU  ----------------------------------------"
echo ""
        echo "$cpu"
echo ""
echo "---------------------------------------------------------------------------------------"
echo ""
echo "----------------------------------------- Disco ---------------------------------------"
echo ""
echo "------------ SDA ------------"
echo ""
if [ $parSda -lt 400 ]; then
	echo -e "** Fora dos padrões **"
	echo ""
	echo "Tamanho da partição: $parSda Gb"
else
	echo "** Partição valida **"
	echo ""
	echo "Tamanho da partição: $parSda Gb"
fi
echo ""
echo "-----------------------------"

echo ""
echo "----------- ROOT ------------"
echo ""
if [ $parRoot -lt 400 ]; then
        echo -e "** Fora dos padrões **"
	echo ""
        echo "Tamanho da partição: $parRoot Gb"
else
        echo "** Partição valida **"
	echo ""
        echo "Tamanho da partição: $parRoot Gb"
fi
echo ""
echo "-----------------------------"

echo ""
echo "----------- SWAP ------------"
echo ""
if [ $parSwp -lt 4096 ]; then
        echo -e "** Fora dos padrões **"
	echo ""
        echo "Tamanho da partição: $parSwp Mb"
else
        echo "** Partição valida **"
	echo ""
        echo "Tamanho da partição: $parSwp Mb"
fi
echo ""
echo "-----------------------------"


echo ""
        echo "$disk"
echo ""

echo "---------------------------------------------------------------------------------------"
echo ""
echo "------------------------------------- Versão CentOS -----------------------------------"
echo ""

if [ "$versionOs" == "7.9" ]; then
        echo "** Versão CORRETA **"
	echo""
	echo "$veros"
else
        echo -e "** Versão incorreta **"
	echo ""
        echo "$veros"

fi

echo ""
echo "---------------------------------------------------------------------------------------"
echo ""
echo "----------------------------------- ERROS DE MEMORIA ----------------------------------"
echo ""

if [ -z $erroMemoria ]; then
        echo "NÃO EXISTEM ERROS DE MEMORIA"
else
        echo -e "Erros encontrados"
        cd /usr/wildfly/bin && ls -ltrh | grep "hs_err"

fi

echo ""
echo "---------------------------------------------------------------------------------------"
echo ""
echo "------------------------------------- Desligametos ------------------------------------"
echo ""

sudo last -n40 -xF shutdown reboot

echo ""
echo "---------------------------------------------------------------------------------------"
echo ""
echo "------------------------------------ Smart do Disco -----------------------------------"
echo ""

sudo smartctl -a /dev/sda

echo ""
echo "---------------------------------------------------------------------------------------"
echo ""
echo "-------------------------------- Teste de escrita DISCO -------------------------------"
echo ""

echo "Rode o comando: 'dd if=/dev/zero of=teste.img bs=512 count=1000 oflag=dsync'"
echo "COPIE O RESULTADO DO COMANDO ACIMA E COLE NESSE BLOCO"

echo ""
echo "---------------------------------------------------------------------------------------"
echo ""
