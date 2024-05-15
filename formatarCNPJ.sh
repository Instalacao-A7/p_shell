#!/bin/bash
# Criado por Kivya Pottechi

# Função para formatar CNPJ com pontuações
formatar_cnpj() {
    # Capturar o CNPJ da área de transferência
    cnpj_selecionado=$(xclip -selection clipboard -o)
    
    # Inicializar variável para armazenar o CNPJ formatado
    cnpj_formatado=""

    # Percorrer cada caractere do CNPJ
    for ((i=0; i<${#cnpj_selecionado}; i++)); do
        char="${cnpj_selecionado:$i:1}"
        # Verificar se o caractere é um dígito numérico
        if [[ "$char" =~ [0-9] ]]; then
            cnpj_formatado+="$char"
        fi
    done

    # Verificar se o CNPJ tem 14 dígitos
    if [ ${#cnpj_formatado} -ne 14 ]; then
        zenity --error --text="Nenhum CNPJ válido foi encontrado na área de transferência.\n\nConteúdo copiado: $cnpj_selecionado"
        exit 1
    fi

    # Adicionar pontuações
    cnpj_formatado="${cnpj_formatado:0:2}.${cnpj_formatado:2:3}.${cnpj_formatado:5:3}/${cnpj_formatado:8:4}-${cnpj_formatado:12:2}"
    echo "$cnpj_formatado"
}

# Chamar a função de formatação do CNPJ
cnpj_formatado=$(formatar_cnpj)

# Colar o CNPJ formatado na área de transferência
echo -n "$cnpj_formatado" | xclip -selection clipboard

# Simular a digitação do CNPJ formatado usando xdotool
xdotool type --delay 100 " $cnpj_formatado"
