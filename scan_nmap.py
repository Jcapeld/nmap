#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import threading
import time
import sys
import os
from datetime import datetime

# ─────────────────── Colores ANSI ────────────────────
green   = "\033[0;32m\033[1m"
red     = "\033[0;31m\033[1m"
blue    = "\033[0;34m\033[1m"
yellow  = "\033[0;33m\033[1m"
gray    = "\033[0;37m\033[1m"
endc    = "\033[0m"

# ─────────────────── Spinner / parpadeo ───────────────
class Spinner:
    def __init__(self, msg="Generando archivo..."):
        self.msg = msg
        self._stop_event = threading.Event()
        self.thread = threading.Thread(target=self._spinner, daemon=True)

    def _spinner(self):
        while not self._stop_event.is_set():
            sys.stdout.write(f"\r\033[5m{self.msg}\033[0m")
            sys.stdout.flush()
            time.sleep(0.5)
        # Limpia la línea al salir
        sys.stdout.write("\r" + " " * len(self.msg) + "\r")
        sys.stdout.flush()

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self._stop_event.set()
        self.thread.join()

# ─────────────────── Funciones principales ────────────
def run_cmd(cmd: str):
    """Ejecuta un comando de shell y muestra salida en tiempo real."""
    subprocess.run(cmd, shell=True)

def scan_network():
    cid = input(f"{blue}Introduce el CIDR de la red ➜ {endc}")
    print(f"{gray}Escaneando red {cid}...{endc}")
    resp = input(f"{yellow}¿Guardar en XML? (Y/n) ➜ {endc}").strip().lower()

    if resp in ("y", ""):
        cmd = f"nmap -sn -n -T5 {cid} --min-rate 1000 -oX device_scan.xml"
        with Spinner():
            run_cmd(cmd)
        print(f"{green}Archivo device_scan.xml generado ✅{endc}")
    else:
        cmd = (
            f"nmap -sn -n -T5 {cid} --min-rate 1000 | "
            r"""awk '/Nmap scan report for/ {ip=$NF} /MAC Address:/ {mac=$3; marca=""; for(i=4;i<=NF;i++) marca=marca" "$i; print ip " - " mac " - " marca}'"""
        )
        run_cmd(cmd)

def scan_port():
    ip = input(f"{blue}IP / host a analizar ➜ {endc}")
    mode = input(f"{blue}¿Todos o más comunes? (Todos/comunes) ➜ {endc}").strip().lower()
    print(f"{gray}Escaneando puertos...{endc}")

    if mode == "todos":
        ports = "-p-"
    else:
        ports = "-p21,22,23,25,27,53,80,143,161,162,389,445"

    cmd = (
        f"nmap -Pn -n -T5 -vv -sV {ports} {ip} --min-rate 1000 | "
        r"""awk '/Nmap scan report for/ {print "IP: "$NF} /^[0-9]+\/tcp/ {print "PORT: "$1" - STATE: "$2" - SERVICE: "$3" - REASON: "$4" - VERSION: "$5} /MAC Address:/ {mac=$3; vendor=""; for(i=4;i<=NF;i++) vendor=vendor" "$i; print "MAC: "mac" - VENDOR:"vendor}'"""
    )
    run_cmd(cmd)

def check_vuln():
    ip    = input(f"{blue}IP a comprobar ➜ {endc}")
    port  = input(f"{blue}Puerto a comprobar ➜ {endc}")
    resp  = input(f"{yellow}¿Guardar resultado en XML? (Y/n) ➜ {endc}").strip().lower()
    print(f"{gray}Escaneando puerto...{endc}")

    if resp in ("y", ""):
        outfile = f"puerto_vulnerable_{ip.replace('.','_')}_{port}_{datetime.now():%Y%m%d_%H%M%S}.xml"
        cmd = f"nmap -sS -Pn -n -T5 -p{port} {ip} --script='default,vuln' -sV -oX {outfile}"
        with Spinner():
            run_cmd(cmd)
        print(f"{green}Archivo {outfile} generado ✅{endc}")
    else:
        cmd = f"nmap -sS -Pn -n -T5 -p{port} {ip} --script='default,vuln' -sV"
        run_cmd(cmd)

# ─────────────────── Menú principal ───────────────────
def main():
    while True:
        print(f"""
{green}¿Qué deseas hacer?{endc}
 1) Escanear una red
 2) Escanear puertos
 3) Verificar si un puerto es vulnerable
 4) Salir
""", end="")
        opt = input("➜ ").strip()

        if opt == "1":
            scan_network()
        elif opt == "2":
            scan_port()
        elif opt == "3":
            check_vuln()
        elif opt == "4":
            print(f"{red}¡Adiós!{endc}")
            break
        else:
            print(f"{red}Opción inválida{endc}")

if __name__ == "__main__":
    # Asegúrate de que nmap esté instalado
    if subprocess.call("command -v nmap > /dev/null", shell=True) != 0:
        print(f"{red}❌ nmap no está instalado. Instálalo y vuelve a intentarlo.{endc}")
        sys.exit(1)
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{red}Interrumpido por el usuario{endc}")

