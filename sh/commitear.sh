#!/bin/bash

# Configuración de colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para manejar errores
handle_error() {
    echo -e "${RED}❌ Error: $1${NC}"
    echo -e "${YELLOW}⚠️  Proceso abortado.${NC}"
    exit 1
}

# Función para limpieza cuando falla el push
cleanup_failed_push() {
    echo -e "\n${YELLOW}Realizando limpieza por fallo...${NC}"
    
    # 1. Quitar del staging tanto el archivo nuevo como el eliminado
    git reset HEAD "$ARCHIVO_DESTINO" || echo -e "${YELLOW}Advertencia: No se pudo sacar del staging${NC}"
    
    # 2. Restaurar archivo original si fue eliminado
    if [ ! -f "$ARCHIVO_ORIGEN" ] && [ -f "$ARCHIVO_DESTINO" ]; then
        mv "$ARCHIVO_DESTINO" "$ARCHIVO_ORIGEN" || echo -e "${YELLOW}Advertencia: No se pudo restaurar archivo original${NC}"
    fi
    
    # 3. Eliminar archivo de historial si existe
    if [ -f "$ARCHIVO_DESTINO" ]; then
        rm "$ARCHIVO_DESTINO" || echo -e "${YELLOW}Advertencia: No se pudo eliminar $ARCHIVO_DESTINO${NC}"
    fi
    
    # 4. Eliminar el commit local (si existe)
    if git cherry -v origin/$(git branch --show-current) | grep -q "$NOMBRE_COMMIT"; then
        git reset --soft HEAD~1 || echo -e "${YELLOW}Advertencia: No se pudo eliminar el commit local${NC}"
    fi
    
    handle_error "No se pudo hacer push después de $MAX_INTENTOS intentos. Se ha revertido la operación."
}

# Verificar que se haya proporcionado un nombre de commit
if [ -z "$1" ]; then
    handle_error "Debes proporcionar un nombre de commit como parámetro.\nUso: $0 <nombre_del_commit>"
fi

# Configuración de rutas
ARCHIVO_ORIGEN="./temp/cambiosAAplicar.sql"
CARPETA_HISTORIAL="./historial"
NOMBRE_USUARIO=$(git config user.name || handle_error "No se pudo obtener el nombre de usuario de Git")
FECHA_HORA=$(date +"%Y%m%d_%H%M%S")
NOMBRE_COMMIT=$1

# Crear carpeta de historial si no existe
mkdir -p "$CARPETA_HISTORIAL" || handle_error "No se pudo crear la carpeta $CARPETA_HISTORIAL"

# Verificar si el archivo origen existe
if [ ! -f "$ARCHIVO_ORIGEN" ]; then
    handle_error "No se encontró el archivo $ARCHIVO_ORIGEN"
fi

# Generar nombre del archivo de historial
ARCHIVO_DESTINO="${CARPETA_HISTORIAL}/${FECHA_HORA}_${NOMBRE_USUARIO}_${NOMBRE_COMMIT// /_}.sql"

# 1. Copiar el archivo al historial (sin eliminarlo aún)
cp "$ARCHIVO_ORIGEN" "$ARCHIVO_DESTINO" || handle_error "Falló al copiar $ARCHIVO_ORIGEN a $ARCHIVO_DESTINO"

# 2. Añadir archivo al staging
git add "$ARCHIVO_DESTINO" || handle_error "Falló al agregar archivo al staging"

# 3. Hacer commit
if ! git commit -m "Historial: $NOMBRE_COMMIT (${FECHA_HORA})"; then
    cleanup_failed_push
fi

# 4. Solo ahora eliminar el archivo original (después del commit exitoso)
if [ -f "$ARCHIVO_ORIGEN" ]; then
    rm "$ARCHIVO_ORIGEN" || echo -e "${YELLOW}Advertencia: No se pudo eliminar $ARCHIVO_ORIGEN${NC}"
fi

# 5. Hacer push con reintentos
MAX_INTENTOS=3
INTENTO=1
PUSH_EXITOSO=false

while [ $INTENTO -le $MAX_INTENTOS ]; do
    echo -e "\n${YELLOW}Intentando push (intento $INTENTO/$MAX_INTENTOS)...${NC}"
    if git push; then
        PUSH_EXITOSO=true
        break
    else
        echo -e "${YELLOW}Push fallido. Reintentando...${NC}"
        sleep 2
        ((INTENTO++))
    fi
done

if [ "$PUSH_EXITOSO" = false ]; then
    cleanup_failed_push
fi

# Resultado final
echo -e "\n${GREEN}✅ Proceso completado exitosamente:${NC}"
echo -e "   - Archivo copiado a: ${GREEN}$ARCHIVO_DESTINO${NC}"
echo -e "   - Commit realizado con mensaje: ${GREEN}'Historial: $NOMBRE_COMMIT'${NC}"
echo -e "   - Cambios pusheados al repositorio remoto"
echo -e "\n${YELLOW}⚠️  Estado actual del repositorio:${NC}"
git status --short