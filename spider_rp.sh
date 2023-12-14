#!/bin/bash

# Colores
red="\e[1;31m"
green="\e[1;32m"
yellow="\e[1;33m"
blue="\e[1;34m"
purple="\e[1;35m"
cyan="\e[1;36m"
reset="\e[0m"

# Cajas de colores (estados)
boxSuccess=$(echo -e ${green}[*]${reset}) # Estado correcto
boxError=$(echo -e ${red}[*]${reset}) # Estado de error
boxWarning=$(echo -e ${yellow}[*]${reset}) # Estado de advertencia
boxInfo=$(echo -e ${cyan}[*]${reset}) # Estado informativo
boxDownload=$(echo -e ${purple}[*]${reset}) # Estado de ejecución

# Archivo de configuración
listaDescargas="listaDescargas.txt"

# Fichero que almacena los archivos encontrados en el servidor
ficheroArchivos="archivos.txt"

# Si no existe el fichero listaDescargas.txt el script pregunta por el nombre del usuario
if [[ ! -f $(pwd)/${listaDescargas} ]]; then
    while true; do
        echo -e -n "\n\t${boxWarning} ${yellow}Digite su nombre completo usando el siguiente orden:\n" \
                   "\tAPELLIDO_PATERNO APELLIDO_MATERNO PRIMER_NOMBRE SEGUNDO_NOMBRE:\n" \
                   "\tNombre: ${reset}"
        read -r NOMBRE_USUARIO

        # Si el nombre de usuario es vacio muestra un mensaje de error y vuelve a preguntar
        if [[ -z "${NOMBRE_USUARIO}" ]]; then
            echo -e "\n\t${boxError} ${red}Necesita agregar su nombre para continuar!${reset}\n" \
                    "\t    ${red}Si desea salir presione la combinación de teclas Ctrl + C${reset}"
            continue
        else
            break
        fi
    done

    # Se crea el archivo listaDescargas.txt y se guarda el nombre del usuario
    echo ${NOMBRE_USUARIO^^} > ${listaDescargas}

    echo -e "\n\t${boxSuccess} ${green}Configuración inicial terminada!\n" \
            "\t    Vuelva a ejecutar el script nuevamente${reset}"
else
    # Se lee el archivo listaDescargas.txt y se guarda en un array
    mapfile -t carpetas < ${listaDescargas}

    # Ciclo para leer el array carpetas
    for carpeta in "${carpetas[@]}"; do
        # Pasar a mayusculas el nombre de la carpeta
        carpeta=${carpeta^^}

        # Si la linea es vacia o comienza con # se salta al siguiente elemento
        if [[ -z ${carpeta} || ${carpeta:0:1} == "#" || ${carpeta:0:1} == "\n" ]]; then
            continue
        fi

        # Se borran los espacios al inicio y final de cada nombre de carpeta leido
        carpeta=$(echo "${carpeta}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

        # Agregar _ a los espacios en blanco para el nombre de la carpeta de guardado
        carpeta_guardado=${carpeta// /_}

        # Crear carpeta si no existe con el nombre de la carpeta de guardado
        if [[ ! -d ${carpeta_guardado} ]]; then
            mkdir -p ${carpeta_guardado} 
        fi
        
        # Entrar a la carpeta de guardado
        cd ${carpeta_guardado} || exit

        # URL de descarga
        url="https://sistemaintegralcarranza.itsjc.edu.mx/vistas/residenciaprofesional/data/${carpeta// /%20}/"

        # Si no existe el fichero archivos.txt se crea y se guarda la lista de archivos encontrados en el servidor
        if [[ ! -f ${ficheroArchivos} ]]; then 
            curl -sS ${url} | grep -oE 'href="[^"]+\.pdf"' | sed 's/href="//;s/"//' | awk -F'/' '{print $NF}' > ${ficheroArchivos}
        fi 

        # Se lee el fichero archivos.txt y se guarda en un array
        mapfile -t archivos < ${ficheroArchivos}

        # Mostrar mensaje de descarga
        echo -e "\n\t${boxInfo} ${cyan}Se esta descargando la carpeta: ${carpeta}${reset}"

        # Ciclo para leer el array archivos
        for archivo in "${archivos[@]}"; do
            # Si el archivo actual existe en el directorio se pasa al siguiente archivo
            if [[ -f ${archivo} ]]; then
                continue
            else    
                # Descargar el archivo en la carpeta actual
                echo -e "\n\t${boxDownload} ${purple}Descargando: ${archivo}${reset}\n"
                curl -o "${archivo}" "${url}/${archivo}"
            fi
        done

        # Regresar a la carpeta anterior
        cd ..

    done
fi