
if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar un nombre de commit como parámetro."
    echo "Uso: $0 <nombre_del_commit>"
    exit 1
fi
# Ejecutar git pull y mostrar la salida mientras se captura
pull_output=$(git pull 2>&1 | tee /dev/tty)

# Verificar si hay conflictos
if [[ $pull_output == *"CONFLICT"* ]]; then
    echo "¡Hay conflictos después del git pull! Debes resolverlos manualmente."
else
    echo "Git pull se completó sin conflictos. ¡Todo está actualizado!"
    ./sh/generar_sql.sh "$1"
fi