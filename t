#!/bin/bash
#  Gestión de copia de seguridad del directorio notes-zim-ok (contiene
#  notas manejadas con zim) a una memoria USB montada en /media/[memoriaUSB]
# Uso: copiaseguridad [memoriaUSB]
#
# Admite algunos trucos:
#  copiaseguridad k    -> copiaseguridad KINGSTON
#  copiaseguridad v    -> copiaseguridad VERBATIM32
#
# Avisos::
# Directorios que se manejan:
# 
# DIR_BAK="/home/naldoco/Backup"
# IF1="/home/naldoco/notes-zim-ok"
#

appName="* * * USB backup management application * * *"

DISK=${1-"VERBATIM32"}
if [ $DISK == "k" ] ; then
    DISK="KINGSTON"
elif [ $DISK == "v" ] ; then
    DISK="VERBATIM32"
elif [ $DISK == "4" ] ; then
    DISK="4937-DB01"
fi


if [ `hostname` ==  naldoco9 ] ; then
    # curro
    PC="n9"
elif [ `hostname` == naldoco1 ] ; then
    # acer aspiere one (AA1)
    PC="n1"
elif [ `hostname` == naldoco2 ] ; then
    # cofiman
    PC="n2"
elif [ `hostname` == naldoco7 ] ; then
    # system76
    PC="n7"
else
    # otros
    PC="nX"
fi


function checkDirectory()
{
if [ -d "$1" ]; then
  echo "El directorio $1 existe. OK."
else
  if [ -e "$1" ]; then
    echo "Hay un fichero llamado $1. Debería ser un directorio.DEBE ARREGLARLO."
    exit
  fi
  mkdir "$1"
  echo  "Se ha creado el directorio $1."
fi
}

isUsbPlugged()
# Primer parámetro ($1): disco usb a verificar.
{
usbInfo=`df | grep $1`
while [ "$usbInfo" == "" ]
do
  echo    "Conecte por favor la memoria usb denominada $DISK."
  echo -n "Para continuar pulse Intro. (Para interrumpir el programa, pulse Ctrl-C) "
  read
  usbInfo=`df | grep $1`
  echo
done
echo "usb: $usbInfo"
echo "Pulse Intro para utilizar el usb que se detalla en la línea anterior".
read
}

function notesPCtoUSB()
{
echo "* * * Copia de datos de ZIM del ordenador a la memoria usb. (Backup) * * *"

isUsbPlugged $DISK

DIR_BAK="/home/naldoco/Backup"
checkDirectory "$DIR_BAK"

# 1) Notas
IF1="/home/naldoco/notes-zim-ok"
OF1="$DIR_BAK/notes-zim-ok-$PC-$(date +%Y%m%d).tar"

# $OF1 debería no estar creado
if [ -e "$OF1" ]; then
  echo "El fichero $OF1 existe."
  echo "** Debería borrarlo ahora para continuar. ^C para salir del script **".
  rm -i "$OF1"
fi

# 1) Copia seguridad de /home/naldoco/notes-zim-ok
# se debe copiar el árbol completo.
# tar:
# -P, --absolute-names ->  don’t strip leading ‘/’s from file names
# -r, --append         ->  append files to the end of an archive

### RCC poner "echo " delante de la siguiente línea para debug
##  find "$IF1" -type f -exec tar -Pvrf "$OF1"_1 {} +
find "$IF1" -path '/home/naldoco/notes-zim-ok/.git' -prune -o -path '/home/naldoco/notes-zim-ok/.bzr' -prune -o  -type f -exec tar -Pvrf "$OF1" {} +

echo;echo RESUMEN:
echo =========
echo "find $IF1  -type f -exec tar -Pvrf  $OF1  {} +"; echo
ls -l "$OF1" ; echo =========

#  Copiar notas
echo -n "¿Copiar $OF1 a memoria USB? "
read
cp -i "$OF1" /media/$DISK
echo -n "Espere a que termine de escribir en la memoria USB y pulse intro. "
sync
read
ls -lt /media/$DISK/*$PC*
}
## End of notesPCtoUSB()


function notesUSBtoPC()
{
echo "* * * Copia de datos de ZIM de la memoria usb al ordenador * * *"

isUsbPlugged $DISK

DIR_ZIM="/home/naldoco/tmp/directories/notes-zim-ok"
checkDirectory "$DIR_ZIM"
DIR_ZIM_BAK="/home/naldoco/tmp/directories/notes-zim-ok.bak"
checkDirectory "$DIR_ZIM_BAK"
DIR_ZIM_BAK2="/home/naldoco/tmp/directories/notes-zim-ok.bak2"
checkDirectory "$DIR_ZIM_BAK2"
echo uno
read
cd /

ls -lt /media/$DISK/notes-zim-ok-n*

echo "(Ctrl-C para abandonar): "
echo -n "Indique fecha según el nombre de archivo [$(date +%Y%m%d)] : "
read FECHA
FECHA=${FECHA:-$(date +%Y%m%d)}

echo -n "Indique ordenador según el nombre de archivo (p. ej: 9 -> trabajo): "
read ORDENADOR
IF1="/media/$DISK/notes-zim-ok-n$ORDENADOR-$FECHA.tar"

echo; echo "Ficheros a procesar:"
ls -l $IF1

echo
echo -n "¿Continuar? -> pulse intro;  Salir -> pulse Ctrl-C."
read -e FOO

# zim:
echo ZIM;echo ====================
rm -rf "$DIR_ZIM_BAK2"
mv "$DIR_ZIM_BAK"  "$DIR_ZIM_BAK2"
mkdir "$DIR_ZIM_BAK"

#mv "$DIR_ZIM"  "$DIR_ZIM_BAK"
### RCC move all content

echo a
ls "$DIR_ZIM/*  $DIR_ZIM_BAK2"
echo b
ls "$DIR_ZIM/*  $DIR_ZIM_BAK2" 
echo c
ls $DIR_ZIM/*   $DIR_ZIM_BAK2
echo d
ls "$DIR_ZIM"/*   $DIR_ZIM_BAK2
echo e

mv "$DIR_ZIM/"*  "$DIR_ZIM_BAK"
echo no ocultos
read
mv "$DIR_ZIM/".* "$DIR_ZIM_BAK" 2>/dev/null
echo ocultos
read
echo mv "$DIR_ZIM/*"  "$DIR_ZIM_BAK"
echo mv "$DIR_ZIM/.*" "$DIR_ZIM_BAK" 2>/dev/null



read
echo

# Mostrar estado de los directorios
ls -l --directory $DIR_ZIM_BAK
echo -n "Elementos: "
find  $DIR_ZIM_BAK |wc -l
ls -l --directory $DIR_ZIM_BAK2
echo -n "Elementos: "
find  $DIR_ZIM_BAK2 |wc -l

echo
echo "¿Listo para extraer el directorio"
echo -n "$DIR_ZIM ? "
read -e FOO
echo
ejecuta1="tar -xvf $IF1"
$ejecuta1
echo
# Mostrar estado de los directorios
ls -l --directory $DIR_ZIM
echo -n "Elementos: "
find  $DIR_ZIM |wc -l
ls -l --directory $DIR_ZIM_BAK
echo -n "Elementos: "
find  $DIR_ZIM_BAK |wc -l
ls -l --directory $DIR_ZIM_BAK2
echo -n "Elementos: "
find  $DIR_ZIM_BAK2 |wc -l

echo
echo -n "¿Correcto? "
read -e FOO

dirdiff "$DIR_ZIM"  "$DIR_ZIM_BAK"
echo "OK. Bye!"
}
## End of notesPCtoUSB()

function scrapbookToUSB() {
echo "* * * Copia de seguridad de los ficheros exportados de Scrapbook * * *"

isUsbPlugged $DISK

# 2) Copia seguridad de /home/naldoco/Desktop/A casa/Scrapbook/ExportImport
# se debe copiar el árbol completo.
# tar:
# -P, --absolute-names ->  don’t strip leading ‘/’s from file names
# -r, --append         ->  append files to the end of an archive

## IF4='"/media/sda1/Documents and Settings/reynaldo.cordero/Escritorio/2009/Scrapbook/2009"'
IF2="/home/naldoco/Desktop/A casa/Scrapbook/ExportImport"
IF2_OK="/home/naldoco/Desktop/A casa/Scrapbook/ExportImport-$(date +%Y%m%d)"

# 2) ScrapBook
# Scrapbook 2009 "/media/sda1/Documents and Settings/reynaldo.cordero/Escritorio/2009/Scrapbook/2009"
#IF2="/home/naldoco/Desktop/A casa/Scrapbook/ExportImport"
## IF4=${IF4-"/home/naldoco/Scrapbook/2009"}
OF2="$IF2/../scrapbookExportImport2009-$PC-$(date +%Y%m%d).tar"
OF2_LOG="$OF2.log"

if [ -e "$OF2" ]; then
  echo "El fichero $OF2 existe."
  echo "** Debería borrarlo para continuar. ^C para salir del script **".
  rm -i "$OF2" "$OF2_LOG"
fi

### OJO BORRA la palabra "echo" de la siguiente línea, para el script final
find "$IF2" -type f -exec tar -Pvrf "$OF2" {} +

echo;echo RESUMEN:
echo =========
echo "find $IF2  -type f -exec tar -Pvrf  $OF2  {} +"; echo
ls -l "$IF2" >  "$OF2_LOG"
ls -l "$OF2" "$OF2_LOG"; echo =========

#  Copiar scrapbook
echo -n "¿Copiar $OF2 y $OF2_LOG a memoria USB? "
read

cp -i "$OF2" "$OF2_LOG" /media/$DISK
echo -n "Espere a que termine de escribir en la memoria USB y pulse intro. "
sync
read

### RCC poner "echo " delante de la siguiente línea para debug
mv "$IF2" "$IF2_OK"
mkdir "$IF2"

ls -lt /media/$DISK/*$PC*
}
## End of scrapbookToUSB()

PS3='Pick an option: '
echo

function choice_of()
{
select option
do
# [in list] omitted, so 'select' uses arguments passed to function.
  if [ "$option" == "NotesPCtoUSB" ] ; then
    notesPCtoUSB
    echo "$appName"
  fi
  if [ "$option" == "NotesUSBtoPC" ] ; then
    notesUSBtoPC
    echo "$appName"
  fi
  if [ "$option" == "Scrapbook" ] ; then
    scrapbookToUSB
    echo "$appName"
  fi
  if [ "$option" == "Umount" ] ; then
    sync
### RCC poner "echo " delante de la siguiente línea para debug
    umount  /media/$DISK
  fi
  if [ "$option" == "Exit" ] ; then
    echo "Bye!"
    exit 0
  fi
done
}
## End of choice_of()


while [ 1 ]
do
echo "$appName"
  choice_of NotesPCtoUSB NotesUSBtoPC Scrapbook Umount Exit
#         $1    $2   $3      $4       $5       $6
#         passed to choice_of() function
done

exit 0

### BORRA ###
### Obsolete function
function DesmontarSN() {
  echo -n "¿Quiere desmontar la  memoria /media/$DISK, y salir ahora? [s]/n "
  read answer
  answer=${answer:-"s"}
  if [ "$answer" == "s" ]; then
    sync
    umount  /media/$DISK
    echo "OK. Bye!"
    exit 0
  fi
}
