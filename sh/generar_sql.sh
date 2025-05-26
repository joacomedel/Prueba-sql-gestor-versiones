#!/bin/bash
if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar un nombre de commit como parámetro."
    echo "Uso: $0 <nombre_del_commit>"
    exit 1
fi
# Archivo de salida
if [ ! -d "./temp" ]; then
    mkdir -p "./temp"
    echo "Carpeta creada: ./temp"
fi
OUTPUT_FILE="./temp/cambiosAAplicar.sql"

# 1. Limpiar archivo existente o crear nuevo
> "$OUTPUT_FILE"

# 2. Obtener archivos en staging (formato nombre)
FILES_IN_STAGE=$(git diff --name-only --cached)

# 3. Verificar si hay archivos en staging
if [ -z "$FILES_IN_STAGE" ]; then
    echo "No hay archivos en staging (git add)." >> "$OUTPUT_FILE"
    echo "No hay archivos en staging (git add)." 
    exit 0
fi
# echo "BEGIN;" >> "$OUTPUT_FILE"
# 4. Recorrer cada archivo y guardar su contenido COMPLETO (versión en staging)
echo "$FILES_IN_STAGE" | while IFS= read -r file; do
    if [[ "$file" != *.sql ]]; then
        echo "❌ $file no se agrega porque no es un archivo .sql"
        continue
    fi

    echo "✅ Se agrega el archivo $file"
    if [ -f "$file" ]; then
        echo "-- === Contenido completo de $file (staging) ===" >> "$OUTPUT_FILE"
        git show :"$file" >> "$OUTPUT_FILE"
        echo ";" >> "$OUTPUT_FILE"
        echo -e "\n" >> "$OUTPUT_FILE"
    else
        echo "-- === $file (archivo borrado en staging) ===" >> "$OUTPUT_FILE"
        #deberia meter comando sql para borrar sp
    fi
done


echo "✅ Contenido COMPLETO de los archivos en staging guardado en $OUTPUT_FILE"
./sh/ejecutar_sql.sh "$1"