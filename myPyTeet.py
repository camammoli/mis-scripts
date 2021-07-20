#!/usr/bin/python3
# -*- coding: utf-8 -*-

from secrets import *
from twython import Twython
import argparse
 
parser = argparse.ArgumentParser(description="Publica en twitter")
parser.add_argument("-v", "--version", help="Mostrar información de versión", action="store_true")
parser.add_argument("-e", "--estado", help="Indicar el contenido del tweet")
args = parser.parse_args()

if args.version:
    print ("Versión 0.1.0a")

if args.estado:
    if len(args.estado) < 2:
        print ("ESTADO debe tener una longitud de (al menos) 2 caracteres")
    else:
        CUSTOMER_KEY = secret_KEY
        CUSTOMER_SECRET= secret_SECRET
        ACCESS_TOKEN = secret_TOKEN
        ACCESS_TOKEN_SECRET = secret_TOKEN_SECRET
        twitter = Twython(CUSTOMER_KEY, 
                          CUSTOMER_SECRET, 
                          ACCESS_TOKEN, 
                          ACCESS_TOKEN_SECRET)
        resultado = twitter.update_status(status=args.estado)
