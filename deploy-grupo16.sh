#!/bin/bash

REPO="bootcamp-devops-2023"
USERID=$(id -u)
echo "DEPLOY START"
echo "-------------"

#Validar Superusuario
if [ "${USERID}" -ne 0 ];
then
    echo "Ejecutar con usuario Root"
    exit
fi


#Actualizar servidor repositorio de paquetes
apt-get update
echo "Servidor actualizado"

#Instalación/validación de Git
if git &> /dev/null ;
    then
        echo "Git ya está instalado"
    else
        apt install git -y
        echo "Instalación correcta"
fi

#Deploy y configuración de BD
if dpkg -s mariadb-server > /dev/null 2>&1 ;
then
    echo "MariaDB ya está instalado"
else
    echo "Instalando mariadb-server"
    apt install mariadb-server -y
    systemctl start mariadb
    systemctl enable mariadb
mysql -e "
MariaDB > CREATE DATABASE devopstravel;
MariaDB > CREATE USER 'codeuser'@'localhost' IDENTIFIED BY 'codepass';
MariaDB > GRANT ALL PRIVILEGES ON *.* TO 'codeuser'@'localhost';
MariaDB > FLUSH PRIVILEGES;"

#Agregar datos a la BD devopstravel
mysql < database/devopstravel.sql


#Instalación/Validación/Activación de Apache y PHP

paquetes=('apache2' 'php' 'libapache2-mod-php' 'php-mysql' 'php-mbstring' 'php-zip' 'php-gd' 'php-json' 'php-curl' )

for i in "${paquetes[@]}"
do
    if dpkg -s $i > /dev/null 2>&1 ;
    then
        echo "$i ya está instalado"
    else
        echo "Instalando $i"
            apt install $i -y
    fi
done

systemctl start "${paquetes[0]}"
systemctl enable "${paquetes[0]}"

echo ""
echo "-------------------"

#Validación de Directorio
if [ -d "$REPO" ] ;
then
    echo "Directorio $REPO existe"
    rm -rf $REPO
fi

#Clonación de repositorio
echo "Instalando Web"
sleep 1
git clone https://github.com/brianleomelo/$REPO.git
cp -r $REPO/app-295devops-travel/* /var/www/html
sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
systemctl reload apache2

echo "-----------------"

