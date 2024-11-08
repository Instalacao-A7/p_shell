#!/usr/bin/env bash

echo "########################################################"
echo " 		    Iniciando Procedimentos                   "
echo "########################################################"

echo -n "Senha do usuário postgres: "
read -s PGPASSWORD
echo
export PGPASSWORD

echo -n "Digite ID chamado: "
read idchamado
echo "Protocolo: $idchamado" | tee -a leitura_monnera.log


echo ""
echo ""
echo -n "Digite uma senha MUITO FORTE para o usuário leitura_monnera:"
read password

source /etc/wildfly.conf

PG_DATA=$(ps aux | grep -oP '^postgres .*postmaster.*-D *\K.*')
PG_VERSION=$(cat $PG_DATA/PG_VERSION)


DropRole="DROP ROLE IF EXISTS leitura_monnera;"

CreateRole="CREATE ROLE leitura_monnera login password '$password' nosuperuser inherit nocreatedb nocreaterole connection limit 5;"

GrantPermissions="GRANT USAGE ON SCHEMA public TO leitura_monnera;


QueryTeste="SELECT * FROM unidadenegocio LIMIT 1;"

RevokeDrop="REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public from leitura_monnera;
REVOKE ALL PRIVILEGES ON SCHEMA public from leitura_monnera;
DROP ROLE IF EXISTS leitura_monnera;"


echo "Removendo a ROLE leitura_monnera se existir"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$RevokeDrop"

echo " "

echo "Criando ROLE leitura_monnera"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$CreateRole"

echo " "

CREATE OR REPLACE VIEW public.v_monnera_classificacao AS 
 SELECT classificacao.id,
    classificacao.profundidade AS nivel,
    classificacao.nome,
    classificacao.caminho,
    true AS ativo,
    ''::text AS cadastro,
    ''::text AS alteracao
   FROM classificacao;

ALTER TABLE public.v_monnera_classificacao
  OWNER TO postgres;
GRANT ALL ON TABLE public.v_monnera_classificacao TO postgres;
GRANT SELECT ON TABLE public.v_monnera_classificacao TO leitura_monnera;



CREATE OR REPLACE VIEW public.v_monnera_estorno AS 
 SELECT venda.id AS vendaid,
    venda.datahorafechamento,
    venda.coo,
    embalagem.codigobarras,
    embalagem.id AS embalagemid,
    itemvenda.id AS itemvendaid,
    itemvenda.quantidade,
    itemvenda.valorunitario,
    itemvenda.desconto,
    itemvenda.valortotal,
    itemorcamento.usuarioid AS usuarioorcamento,
    venda.usuarioid AS usuariovenda,
    venda.unidadenegocioid,
    caixa.numero,
    devolucaovenda.id AS iddevolucao_estorno,
    devolucaovenda.datahora AS dataahoradevolucao_estorno,
    devolucaovenda.usuarioid AS usuariodevolucao_estorno,
    itemdevolucaovenda.quantidade AS quantidadevolvida,
    'D'::text AS tipo
   FROM itemdevolucaovenda
     JOIN itemvenda ON itemvenda.id = itemdevolucaovenda.itemvendaid
     LEFT JOIN itemorcamento ON itemorcamento.id = itemvenda.itemorcamentoid
     JOIN devolucaovenda ON devolucaovenda.id = itemdevolucaovenda.devolucaovendaid
     JOIN venda ON venda.id = devolucaovenda.vendaid
     JOIN embalagem ON embalagem.id = itemvenda.embalagemid
     JOIN valecompra ON valecompra.id = devolucaovenda.valecompraid
     JOIN sessaocaixa ON sessaocaixa.id = valecompra.sessaocaixaid
     JOIN caixa ON caixa.id = sessaocaixa.caixaid
UNION ALL
 SELECT venda.id AS vendaid,
    venda.datahorafechamento,
    venda.coo,
    embalagem.codigobarras,
    embalagem.id AS embalagemid,
    itemvenda.id AS itemvendaid,
    itemvenda.quantidade,
    itemvenda.valorunitario,
    itemvenda.desconto,
    itemvenda.valortotal,
    itemorcamento.usuarioid AS usuarioorcamento,
    venda.usuarioid AS usuariovenda,
    venda.unidadenegocioid,
    caixa.numero,
    estornovenda.id AS iddevolucao_estorno,
    estornovenda.datahora AS dataahoradevolucao_estorno,
    estornovenda.usuarioid AS usuariodevolucao_estorno,
    itemvenda.quantidade AS quantidadevolvida,
    'E'::text AS tipo
   FROM estornovenda
     JOIN venda ON venda.id = estornovenda.vendaid
     JOIN itemvenda ON itemvenda.vendaid = venda.id
     LEFT JOIN itemorcamento ON itemorcamento.id = itemvenda.itemorcamentoid
     JOIN embalagem ON embalagem.id = itemvenda.embalagemid
     JOIN caixa ON caixa.id = estornovenda.caixaid;

ALTER TABLE public.v_monnera_estorno
  OWNER TO chinchila;
GRANT ALL ON TABLE public.v_monnera_estorno TO chinchila;
GRANT SELECT ON TABLE public.v_monnera_estorno TO leitura_monnera;

CREATE OR REPLACE VIEW public.v_monnera_fabricante AS 
 SELECT fabricante.id AS codigo,
    pessoa.razaosocial AS razao_social,
    pessoa.nome,
    pessoa.cnpj
   FROM fabricante
     JOIN pessoa ON pessoa.id = fabricante.pessoaid;

ALTER TABLE public.v_monnera_fabricante
  OWNER TO chinchila;
GRANT ALL ON TABLE public.v_monnera_fabricante TO chinchila;
GRANT SELECT ON TABLE public.v_monnera_fabricante TO leitura_monnera;

CREATE OR REPLACE VIEW public.v_monnera_fornecedor AS 
 SELECT fornecedor.id AS codigo,
    pessoa.razaosocial AS razao_social,
    pessoa.nome,
    pessoa.cnpj,
        CASE
            WHEN fornecedor.status = 'A'::bpchar THEN 'ATIVO'::text
            WHEN fornecedor.status = 'I'::bpchar THEN 'INATIVO'::text
            ELSE NULL::text
        END AS status
   FROM fornecedor
     JOIN pessoa ON pessoa.id = fornecedor.pessoaid;

ALTER TABLE public.v_monnera_fornecedor
  OWNER TO chinchila;
GRANT ALL ON TABLE public.v_monnera_fornecedor TO chinchila;
GRANT SELECT ON TABLE public.v_monnera_fornecedor TO leitura_monnera;


CREATE OR REPLACE VIEW public.v_monnera_grupo_usuario AS 
 SELECT grupousuario.id,
    grupousuario.nome
   FROM grupousuario;

ALTER TABLE public.v_monnera_grupo_usuario
  OWNER TO postgres;
GRANT ALL ON TABLE public.v_monnera_grupo_usuario TO postgres;
GRANT SELECT ON TABLE public.v_monnera_grupo_usuario TO leitura_monnera;

CREATE OR REPLACE VIEW public.v_monnera_loja AS 
 SELECT unidadenegocio.id,
    unidadenegocio.codigo,
    unidadenegocio.status,
    unidadenegocio.cnpj,
    unidadenegocio.nomefantasia,
    unidadenegocio.razaosocial,
    unidadenegocio.cep
   FROM unidadenegocio
  WHERE unidadenegocio.codigo::text <> 'CLOUD'::text
  ORDER BY unidadenegocio.codigo;

ALTER TABLE public.v_monnera_loja
  OWNER TO postgres;
GRANT ALL ON TABLE public.v_monnera_loja TO postgres;
GRANT SELECT ON TABLE public.v_monnera_loja TO leitura_monnera;


CREATE OR REPLACE VIEW public.v_monnera_produtos AS 
 SELECT embalagem.id AS embalagemid,
    produto.id AS produtoid,
    embalagem.descricao AS embalagem,
    produto.descricao AS produto,
    classificacaoproduto.classificacaoid,
    sum(estoque.estoque) AS estoque,
    estoqueminimoprodutounidadenegocio.estoqueminimo,
    embalagem.codigobarras,
    produto.fabricanteid,
    embalagem.unidademedidacomercial,
        CASE
            WHEN produto.status = 'A'::bpchar THEN true
            ELSE false
        END AS ativo,
    produto.datahorainclusao
   FROM embalagem
     JOIN produto ON produto.id = embalagem.produtoid
     JOIN classificacaoproduto ON classificacaoproduto.produtoid = produto.id
     JOIN classificacao ON classificacao.id = classificacaoproduto.classificacaoid
     LEFT JOIN estoque ON estoque.embalagemid = embalagem.id
     LEFT JOIN estoqueminimoprodutounidadenegocio ON estoqueminimoprodutounidadenegocio.produtoid = produto.id
  WHERE classificacao.principal = true
  GROUP BY embalagem.id, produto.id, embalagem.descricao, produto.descricao, classificacaoproduto.classificacaoid, estoqueminimoprodutounidadenegocio.estoqueminimo
  ORDER BY produto.id;

ALTER TABLE public.v_monnera_produtos
  OWNER TO chinchila;
GRANT ALL ON TABLE public.v_monnera_produtos TO chinchila;
GRANT SELECT ON TABLE public.v_monnera_produtos TO leitura_monnera;


CREATE OR REPLACE VIEW public.v_monnera_saida AS 
 SELECT DISTINCT venda.id AS vendaid,
    venda.datahorafechamento,
    venda.coo,
    embalagem.codigobarras,
    embalagem.id AS embalagemid,
    itemvenda.id AS itemvendaid,
    itemvenda.quantidade,
    itemvenda.valorunitario,
    itemvenda.desconto,
    itemvenda.valortotal,
    itemorcamento.usuarioid AS usuarioorcamento,
    venda.usuarioid AS usuariovenda,
    venda.unidadenegocioid,
    caixa.numero
   FROM itemvenda
     JOIN venda ON venda.id = itemvenda.vendaid
     JOIN embalagem ON embalagem.id = itemvenda.embalagemid
     JOIN caixa ON caixa.id = venda.caixaid
     LEFT JOIN itemorcamento ON itemorcamento.id = itemvenda.itemorcamentoid
  WHERE venda.status = 'F'::bpchar AND itemvenda.status = 'F'::bpchar;

ALTER TABLE public.v_monnera_saida
  OWNER TO postgres;
GRANT ALL ON TABLE public.v_monnera_saida TO postgres;
GRANT SELECT ON TABLE public.v_monnera_saida TO leitura_monnera;


CREATE OR REPLACE VIEW public.v_monnera_usuarios AS 
 SELECT DISTINCT usuario.id AS codigo,
    usuario.login,
        CASE
            WHEN usuario.status = 'A'::bpchar THEN true
            ELSE false
        END AS usuarioativo,
    usuario.apelido AS nome,
    usuarioparticipantegrupousuario.grupousuarioid,
    COALESCE(regexp_replace(pessoa.cpf::text, '[^0-9]'::text, ''::text, 'g'::text), ''::text)::character varying(11) AS cpf,
    'F'::text AS tipopessoa,
    usuario.email,
    usuario.unidadenegocioid,
        CASE
            WHEN pessoa.status = 'A'::bpchar THEN true
            ELSE false
        END AS pessoaativa,
    pessoa.datahorainclusao
   FROM usuario
     LEFT JOIN pessoa ON pessoa.id = usuario.pessoaid
     LEFT JOIN usuarioparticipantegrupousuario ON usuarioparticipantegrupousuario.usuarioid = usuario.id;

ALTER TABLE public.v_monnera_usuarios
  OWNER TO chinchila;
GRANT ALL ON TABLE public.v_monnera_usuarios TO chinchila;
GRANT SELECT ON TABLE public.v_monnera_usuarios TO leitura_monnera;"

echo " "

echo "Dando as devidas pemissões para a ROLE leitura_monnera"
psql -X -h $END_SERVIDOR -U postgres -d $CHINCHILA_DS_DATABASENAME --command="$GrantPermissions"



 if [[ "$PG_VERSION" == "14" ]]; then
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/leitura_monnera/d' pg_hba.conf
	echo "host	all		leitura_monnera	samenet			scram-sha-256" >> pg_hba.conf
	echo ""
	echo
	echo ""
   
 else
	cd /var/lib/pgsql/$PG_VERSION/data/
	sed -i '/leitura_monnera/d' pg_hba.conf
	echo "host	all		leitura_monnera	samenet			md5" >> pg_hba.conf
	echo ""
	echo
	echo ""
 fi			

service postgresql-$PG_VERSION reload

psql -X -h $END_SERVIDOR -U "leitura_monnera" -d $CHINCHILA_DS_DATABASENAME --password --command="$QueryTeste"

echo " "
echo "########################################################"
echo "Acesso para MONNERA"
echo " "
echo "Usuário: leitura_monnera"
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
	sed -i '/leitura_monnera/d' pg_hba.conf
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
