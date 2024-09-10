#!/bin/bash

# Definir a origem e o destino
origem="/mnt/volume/nextcloud/data/admin/files"
destino="/mnt/backup"
data=$(date '+%Y-%m-%d_%H-%M-%S') # Obter a data atual no formato ano-mês-dia_hora-minuto-segundo
backup_nome="backup_$data.tar.gz" # Nome do arquivo compactado
backup_destino="$destino/$backup_nome"
logfile="/home/andre/logs/backup_$data.log" # Nome do arquivo de log

# Função de log
log() {
    mensagem="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$mensagem" | tee -a "$logfile" # Salvar no arquivo de log e imprimir no console
}

# Verificar se a origem existe
if [ ! -d "$origem" ]; then
    log "A pasta de origem não existe: $origem"
    exit 1
fi

# Criar o diretório de destino se não existir
if [ ! -d "$destino" ]; then
    log "Criando o diretório de destino: $destino"
    mkdir -p "$destino"
fi

# Executar o rsync para copiar os arquivos
log "Iniciando a cópia de $origem para $destino"
rsync -av --progress "$origem" "$destino" | tee -a "$logfile"

# Verificar se a cópia foi bem-sucedida
if [ $? -eq 0 ]; then
    log "Cópia concluída com sucesso!"
    
    # Compactar a pasta copiada
    log "Compactando a pasta de backup em $backup_destino"
    tar -czf "$backup_destino" -C "$destino" "$(basename "$origem")" 2>&1 | tee -a "$logfile"
    
    # Verificar se a compactação foi bem-sucedida
    if [ $? -eq 0 ]; then
        log "Compactação concluída com sucesso! Arquivo: $backup_nome"
        # Remover a pasta original copiada (opcional)
        rm -rf "$destino/$(basename "$origem")"
        log "Pasta original removida após compactação."
    else
        log "Erro durante a compactação."
    fi
else
    log "Ocorreu um erro durante a cópia."
fi

# Excluir backups e manter apenas os 3 arquivos mais recentes
log "Excluindo backups antigos e mantendo apenas os 3 mais recentes"
ls -tp "$destino"/backup_*.tar.gz | grep -v '/$' | tail -n +4 | xargs -I {} rm -- {}
if [ $? -eq 0 ]; then
    log "Backups antigos excluídos com sucesso, mantendo apenas os 3 mais recentes."
else
    log "Erro ao excluir backups antigos."
fi