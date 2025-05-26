#!/bin/bash

# Configuración de la base de datos
DB_HOST="192.9.200.9"
DB_PORT="5432"
DB_NAME="SOSSIGES_BETA"
DB_USER="postgres"
DB_PASS="postgrespostgres"
SQL_FILE="./temp/cambiosAAplicar.sql"
ERROR_FILE="./temp/error.txt"
OUTPUTLOG_FILE = "./temp/output.log"

# Limpiar archivo de errores previo
> "$ERROR_FILE"

# 1. Verificar si el archivo SQL existe
if [ ! -f "$SQL_FILE" ]; then
    echo "❌ Error: No se encontró el archivo $SQL_FILE" | tee -a "$ERROR_FILE"
    exit 1
fi

# 2. Leer contenido del archivo SQL
SQL_CONTENT=$(cat "$SQL_FILE")

# 3. Ejecutar consultas y capturar errores
echo "🔍 Ejecutando consultas desde $SQL_FILE en $DB_HOST..."

# Ejecutar y capturar tanto stdout como stderr
echo "PGPASSWORD=\"$DB_PASS\" psql -h \"$DB_HOST\" -p \"$DB_PORT\" -U \"$DB_USER\" -d \"$DB_NAME\" -c \"$SQL_CONTENT\"" >> "$ERROR_FILE"
PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$SQL_CONTENT" > >(tee -a $OUTPUTLOG_FILE) 2> >(tee -a "$ERROR_FILE" >&2)

# 4. Verificar resultado
if [ $? -eq 0 ]; then
    echo "✅ Consultas ejecutadas correctamente"
    ./sh/commitear.sh "$1"
else
    echo "❌ Error al ejecutar las consultas (ver $ERROR_FILE)"
    # Añadir marca de tiempo al error
    echo -e "\n[Error ocurrido el $(date)]" >> "$ERROR_FILE"
    exit 1
fi