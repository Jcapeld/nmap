#!/bin/bash
# Colores
declare -r greenColour="\e[0;32m\033[1m"
declare -r endColour="\033[0m\e[0m"
declare -r redColour="\e[0;31m\033[1m"
declare -r blueColour="\e[0;34m\033[1m"
declare -r yellowColour="\e[0;33m\033[1m"
declare -r purpleColour="\e[0;35m\033[1m"
declare -r turquoiseColour="\e[0;36m\033[1m"
declare -r grayColour="\e[0;37m\033[1m"
# Funciones
scan_network() {
		echo -ne "${blueColour}Introduce el CIDR de la red ${endColour}\n"
		read cidr
                echo -ne "${grayColour}Escaneando host $cidr.. ${grayColour}\n"
		echo -ne "${yellowColour}Quieres guardar el escaneo en formato XML?(Y/n)${endColour}"
                read respuesta
		if [ "$respuesta" == "Y" ] || [ "$respuesta" == "y" ]; then
                #echo -ne "${greenColour}Generando archivo CSV${endColour}"
                #nmap -sn - -n -T5 $cid --min-rate 1000  > ./device_scan.csv
	(while :; do echo -ne "\r\033[5mGenerando archivo...\033[0m"; sleep 0.5; done) & PID=$!; nmap -sn -n -T5 $cidr --min-rate 1000 -oX device_scan.xml &>/dev/null; kill $PID; wait $PID 2>/dev/null; echo -e "\rArchivo generado ✅"
	else
                echo -ne "${greenColour}Perfecto aqui lo tienes${endColour}\n"
                nmap -sn  -n -T5 "$cidr" --min-rate 1000 | awk '/Nmap scan report for/ {ip=$NF} /MAC Address:/ {mac=$3; marca=""; for(i=4;i<=NF;i++) marca=marca" "$i; print ip " - " mac " -" marca}'
                fi
}



scan_port(){
		echo -ne "${blueColour}IP / Host a analizar${endColour}\n"
                read ip
                echo -ne "${blueColour}Quieres analizar todos los puertos o simplemente los mas comunes?(Todos/comunes)${endColour}"
                read puerto
                echo -ne  "${grayColour}Escaneando puertos ${endColour}\n"
                if [ "$puerto" == "Todos" ] || [ "$puerto" == "todos" ]; then
                nmap -Pn -n -T5 -vv -sV   -p- $ip --min-rate 1000 | awk '/Nmap scan report for/ {print "IP: "
 $NF} /^[0-9]+\/tcp/ {print "PORT: " $1 " - STATE: " $2 " - SERVICE: " $3 " - REASON: " $4 " - VERSION: " $5} /MAC Address:/ {mac=$3; vendor=""; for (i=4;i<=NF;i++) vendor=vendor" "$i; print "MAC: " mac " - VENDOR:" vendor}'
                else
                nmap -Pn -n -T5 -vv -sV   -p21,22,23,25,27,53,80,143,161,162,389,445 $ip --min-rate 1000| awk '/Nmap scan report for/ {print "IP: " $NF} /^[0-9]+\/tcp/ {print "PORT: " $1 " - STATE: " $2 " - SERVICE: " $3 " - REASON: " $4 " - VERSION: " $5} /MAC Address:/ {mac=$3; vendor=""; for (i=4;i<=NF;i++) vendor=vendor" "$i; print "MAC: " mac " - VENDOR:" vendor}'

		fi
}

check_vuln(){
	echo -ne "${blueColour}IP / Host a comprobar ${endColour}\n"
	read ip
	echo -ne "${blueColour}Puerto a comprobar ${endColour}\n"
	read puerto
	echo -ne "${yellowColour}Quieres guardar el resultado en un documento XML?(Y/n) ${endColour}"
        read respuesta
        echo -ne  "${grayColour}Escaneando puerto ${endColour}\n"
        if [ "$respuesta" == "Y" ] || [ "$respuesta" == "y" ]; then
		#echo -ne "${greenColour}\033[5mGenerando archivo CSV\033[0m${endColour}\n"
		#nmap -sS -Pn -n -T5 -p$puerto $ip  --script="default,vuln" -sV > puerto_vuln.csv
	(while :; do echo -ne "\r\033[5mGenerando archivo...\033[0m"; sleep 0.5; done) & PID=$!; nmap -sS -Pn -n -T5 -p$puerto $ip  --script="default,vuln" -sV  -oX puerto_vulnerable.xml &>/dev/null; kill $PID; wait$PID 2>/dev/null; echo -e "\rArchivo generado ✅"

	else
		echo -ne "${greenColour}Perfecto aqui lo tienes${endColour}\n"
		nmap -sS -Pn -n -T5 -p$puerto $ip  --script="default,vuln" -sV
	fi
}
while true; do
echo -ne "${greenColour}Que deseas hacer?${endColour}\n"
echo -ne "${greenColour}1) Escanear una red ${endColour}\n"

echo -ne "${greenColour}2) Escanear puertos ...${endColour}\n"
echo -ne "${greenColour}3) Verificar si un puerto es vulnerable${greenColour}\n"
echo -ne "${redColour}4) Salir${endColour}\n"
read  opcion  
case $opcion in
    1) scan_network ;;
    2) scan_port ;;
    3) check_vuln ;;
    4) echo -ne "${redColour}Adiós!${endColour}" && exit ;;
    *) echo -ne "${redColour}Opción inválida${endColour}\n " ;;
  esac
done
