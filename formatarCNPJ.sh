#!/bin/bash

# Função para formatar CNPJ com pontuações
formatar_cnpj() {
    cnpj=$1
    # Remover todos os caracteres não numéricos
    cnpj=$(echo "$cnpj" | tr -dc '0-9')
    # Verificar se o CNPJ tem 14 dígitos
    if [ ${#cnpj} -ne 14 ]; then
        return 1
    fi
    # Adicionar pontuações
    cnpj_formatado=$(echo "$cnpj" | sed 's/\([0-9]\{2\}\)\([0-9]\{3\}\)\([0-9]\{3\}\)\([0-9]\{4\}\)\([0-9]\{2\}\)/\1.\2.\3\/\4-\5/')
    echo "$cnpj_formatado"
}

# Capturar o CNPJ da área de transferência
cnpj_selecionado=$(xclip -selection clipboard -o)

# Chamar a função de formatação com o CNPJ selecionado
cnpj_formatado=$(formatar_cnpj "$cnpj_selecionado")

# Verificar se a formatação do CNPJ foi bem-sucedida
if [ $? -ne 0 ]; then
    zenity --error --text="Nenhum CNPJ válido foi encontrado na área de transferência.\n\nConteúdo copiado: $cnpj_selecionado"
    exit 1
fi

# Simular a digitação do CNPJ formatado usando xdotool
xdotool type --delay 100 --clearmodifiers " $cnpj_formatado"