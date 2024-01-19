# -*- coding: utf-8 -*-
#Desenvolvido por: Carlos Oliveira e Guilherme Vaz

import os

#Inicializo a lista com opções para o tipo de impressão:
tipoImpressao = [1,2,3]

#Defino demais variáveis que serão utilizadas
url_css = "https://raw.githubusercontent.com/Instalacao-A7/p_shell/main/atendimento.css"
url_logo = "https://drive.google.com/file/d/1AcxJyDV7YM8DEDvXvIlc-LTz4GAIsDxS/view?usp=drive_link"
url_kb = "http://kb.a7.net.br/index.php?curid=1307"
url_kb_tablet = "http://kb.a7.net.br/index.php?curid=876"
AZUL = "\033[94m"
VERDE = "\033[92m"
VERMELHO = "\033[91m"
RESET = "\033[0m"

#Crio o diretório em meu computador, caso não existe e o arquivo para o comando de impressão
diretorioArquivoImpressao = "/home/alpha7"
diretorioArquivosEstilo = "/home/alpha7/chinchila-online-arquivos"
#diretorioArquivoImpressao = "/home/alpha7/MEGA/Python/teste"

print(AZUL + "Criando diretórios...." + RESET)
if not os.path.exists(diretorioArquivoImpressao):
    os.makedirs(diretorioArquivoImpressao)
caminho_arquivo_imp = os.path.join(diretorioArquivoImpressao, "imprimeEtiquetaAtendimento.txt")

#Crio o diretório, caso não exista, onde serão colocados os arquivos de estilo
#diretorioArquivosEstilo = "/home/alpha7/MEGA/Python/chinchila-online-arquivos"
if not os.path.exists(diretorioArquivosEstilo):
    os.makedirs(diretorioArquivosEstilo)
caminho_arquivo_estilo = os.path.join(diretorioArquivosEstilo, "atendimento.css")
caminho_arquivo_logo = os.path.join(diretorioArquivosEstilo, "logo_a7.png")

print(AZUL + "Baixando arquivos..." + RESET)
#Baixo os arquivos neste diretório
os.system("wget {} -O {} ".format(url_css,caminho_arquivo_estilo))
os.system("wget {} -O {} ".format(url_logo,caminho_arquivo_logo))




#Aqui o usuário terá de inserir informações importantes para a aplicação usar na escrita do arquivo com o comando de impressão

while True:
 try:
  userInput = int(raw_input("Onde está conectada a impressora? Digite: \n1 - Tablet\n2 - Tablet com Windows \n3 - Computador com Windows \nSua resposta: "))
  if userInput == tipoImpressao[0]:
      print(VERMELHO + "Você escolheu Tablet" + RESET)
      ipTablet = raw_input("Insira aqui o IP do Tablet: ")
      print(AZUL + "Escrevendo no arquivo..." + RESET)
      with open(caminho_arquivo_imp, 'w') as arquivo:
          arquivo.write('cat "${{1}}" | nc -w 5 {} 3333'.format(ipTablet))
      print(caminho_arquivo_imp)
      confirmacao = raw_input("Oriente o cliente a fixar o IP do Tablet e disponibilize a ele a APK do aplicativo A7Senha para que instale no Tablet, ela está presente no passo 2 do KB abaixo: \n{}.\nEle deverá preencher os campos HOST e Porta, com o IP do servidor e 8080, respectivamente. \nPressione Enter para prosseguir".format(url_kb_tablet))
      break
      
  elif userInput == tipoImpressao[1]:
      print(VERMELHO + "Você escolheu Tablet com Windows" + RESET)
      ipTablet = raw_input("Insira aqui o IP do Tablet: ")
      nomeCompartilhamentoImp = raw_input("Insira o nome de compartilhamento da Impressora: ")
      usuarioWindows = raw_input("Insira o usuário do Windows: ")
      senhaWindows = raw_input("Insira a senha do usuário Windows (se não possuir senha, deixa em branco e somente pressione Enter: ")                          
      print(AZUL + "Escrevendo no arquivo..." + RESET)
      with open(caminho_arquivo_imp, 'w') as arquivo:
                arquivo.write('#!/bin/bash \nsmbclient //{}/{} -U "{}%{}" -c "print ${{1}}"'.format(ipTablet, nomeCompartilhamentoImp, usuarioWindows, senhaWindows))
      break
      
  elif userInput == tipoImpressao[2]:
      print(VERMELHO + "Você escolheu Computador com Windows" + RESET)
      ipComputador = raw_input("Insira aqui o IP do Computador: ")
      nomeCompartilhamentoImp = raw_input("Insira o nome de compartilhamento da Impressora: ")
      usuarioWindows = raw_input("Insira o usuário do Windows: ")
      senhaWindows = raw_input("Insira a senha do usuário Windows (se não possuir senha, deixa em branco e somente pressione Enter: ")                    
      print(AZUL + "Escrevendo no arquivo..." + RESET)      
      with open(caminho_arquivo_imp, 'w') as arquivo:
        arquivo.write('#!/bin/bash \nsmbclient //{}/{} -U "{}%{}" -c "print ${{1}}"'.format(ipComputador,nomeCompartilhamentoImp,usuarioWindows,senhaWindows))
      break
      
  elif userInput > 4 or userInput < 1:
      print(VERMELHO + "Digite um número válido entre as opções: 1,2 ou 3" + RESET)
 
 except ValueError:
     print("Por favor, digite somente números")
    
print("Lembre-se agora de configurar as chaves avançadas a seguir no sistema A7Pharma:\nAtendimento.IPsPermitidos\nAtendimentoSenha.Impressao.Impressora\nAtendimentoSenha.Impressao.Comando")
confirmacao = raw_input("Pressione Enter se já concluiu essa etapa")
ipServidor = raw_input("Agora vamos configurar o link de acesso ao painel de senha\nInsira o endereço IP do Servidor: ")
id_painel = raw_input("É necessário o ID do cadastro do Painel de Atendimento. Caso não tenha feito o cadastro, siga os passos 1 ao 3 do KB abaixo: \n{}\nInsira em seguida o ID: ".format(url_kb))
print("O URL do painel de senha é \nhttp://{}:8080/online/atendimento/painel/?idPainel={}&tempoExibicaoSenha=8. \nCopie e disponibilize para a pessoa interessada".format(ipServidor,id_painel))
print(AZUL + "Concedendo permissão u+x no arquivo com o comando de impressão..." + RESET)
os.system("chmod u+x {}".format(caminho_arquivo_imp))
print(AZUL + "Concluído" + RESET)
confirmacao = raw_input("Pressione enter para finalizar")
quit()
