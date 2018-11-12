#!/bin/sh
 
clear
 
if [ -z "${mysql_roundcube_password}" ]; then
tmp=$(&gt; .passwords
fi
 
if [ -z "${mysql_root_password}" ]; then
read -p "MySQL root password []:" mysql_root_password
fi
 
wget -P /var/www/html "https://github.com/roundcube/roundcubemail/releases/download/1.3.8/roundcubemail-1.3.8-complete.tar.gz"
tar -C /var/www/html -zxvf /var/www/html/roundcubemail-*.tar.gz
rm -f /var/www/html/roundcubemail-*.tar.gz
mv /var/www/html/roundcubemail-* /var/www/html/roundcube
chown root:root -R /var/www/html/roundcube
chmod 777 -R /var/www/html/roundcube/temp/
chmod 777 -R /var/www/html/roundcube/logs/
 
cat &lt;&lt;'EOF' &gt; /etc/httpd/conf.d/20-roundcube.conf
Alias /webmail /var/www/html/roundcube
Options -Indexes
AllowOverride All
Order Deny,Allow
Deny from All
Order Deny,Allow
Deny from All
Order Deny,Allow
Deny from All
 
EOF
 
sed -e "s|mypassword|${mysql_roundcube_password}|" &lt;&lt;'EOF' | mysql -u root -p"${mysql_root_password}"
USE mysql;
CREATE USER 'roundcube'@'localhost' IDENTIFIED BY 'mypassword';
GRANT USAGE ON * . * TO 'roundcube'@'localhost' IDENTIFIED BY 'mypassword';
CREATE DATABASE IF NOT EXISTS `roundcube`;
GRANT ALL PRIVILEGES ON `roundcube` . * TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
EOF
 
mysql -u root -p"${mysql_root_password}" 'roundcube' &lt; /var/www/html/roundcube/SQL/mysql.initial.sql cp /var/www/html/roundcube/config/main.inc.php.dist /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['default_host'\] =\).*$|\1 \'localhost\';|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['smtp_server'\] =\).*$|\1 \'localhost\';|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['smtp_user'\] =\).*$|\1 \'%u\';|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['smtp_pass'\] =\).*$|\1 \'%p\';|" /var/www/html/roundcube/config/main.inc.php #sed -i "s|^\(\$rcmail_config\['support_url'\] =\).*$|\1 \'mailto:${E}\';|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['quota_zero_as_unlimited'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['preview_pane'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['read_when_deleted'\] =\).*$|\1 false;|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['check_all_folders'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['display_next'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['top_posting'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['sig_above'\] =\).*$|\1 true;|" /var/www/html/roundcube/config/main.inc.php sed -i "s|^\(\$rcmail_config\['login_lc'\] =\).*$|\1 2;|" /var/www/html/roundcube/config/main.inc.php cp /var/www/html/roundcube/config/db.inc.php.dist /var/www/html/roundcube/config/db.inc.php sed -i "s|^\(\$rcmail_config\['db_dsnw'\] =\).*$|\1 \'mysqli://roundcube:${mysql_roundcube_password}@localhost/roundcube\';|" /var/www/html/roundcube/config/db.inc.php rm -rf /var/www/html/roundcube/installer service httpd reload Save the file and execute the script: sudo chmond +x ~/roundcubeinstall.sh &amp;&amp; sudo bash ~/roundcubeinstall.sh You will be prompted to fill in RoundCube MySQL password and MySQL root password: MySQL roundcube user password [5PMLswoTYfPO]: MySQL root password []: The script will download the necessary installation package, extract the content inside the proper location and configure the RoundCube webmail client to work with the Apache service. At the end the Apache service will be restarted. 3. Install RoundCube on Debian Open new file and place the following lines inside: sudo nano ~/roundcubeinstall.sh #!/bin/bash [ -z "${log}" ] &amp;&amp; log="install-roundcube.log" [ -z "${errorprefix}" ] &amp;&amp; errorprefix="${0}: " if [ -d bup2 ]; then echo "${errorprefix}directory bup already exists!" 1&gt;&amp;2
exit 1
else
mkdir -p bup2
fi
 
# mysql root password
[ -z "${mysqlrootpasswd}" ] &amp;&amp; read -s -p "mysqlrootpasswd []:" mysqlrootpasswd
echo ''
 
if [ -z "${mysqlroundcubepasswd}" ]; then
tmp=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
read -p "mysqlroundcubepassword [${tmp}]:" mysqlroundcubepasswd
mysqlroundcubepasswd="${mysqlroundcubepasswd:-${tmp}}"
unset tmp
fi
 
# apache webserver root
if [ -z "${httproot}" ]; then
tmp="/var/www"
read -p "httproot [${tmp}]: " httproot
httproot="${httproot:-${tmp}}"
unset tmp
fi
 
# name for roundcube root and apache site
if [ -z "${roundcubesitename}" ]; then
tmp="roundcube"
read -p "roundcubesitename [${tmp}]: " roundcubesitename
roundcubesitename="${roundcubesitename:-${tmp}}"
unset tmp
fi
 
# displayed name on the website
if [ -z "${roundcubeproductname}" ]; then
tmp="Roundcube Webmail"
read -p "roundcubeproductname [${tmp}]: " roundcubeproductname
roundcubeproductname="${roundcubeproductname:-${tmp}}"
unset tmp
fi
 
# leave empty to autodetect from user agent
if [ -z "${roundcubelanguage}" ]; then
tmp="en_US"
read -p "roundcubelanguage [${tmp}]: " roundcubelanguage
roundcubelanguage="${roundcubelanguage:-${tmp}}"
unset tmp
fi
 
# linux username (required for cronjob)
if [ -z "${user}" ]; then
tmp="root"
read -p "user [${tmp}]: " user
user="${user:-${tmp}}"
unset tmp
fi
 
# domain name
if [ -z "${domain}" ]; then
tmp="yourdomain.tld"
read -p "domain [${tmp}]: " domain
domain="${domain:-${tmp}}"
unset tmp
fi
 
roundcuberoot="${httproot}/${roundcubesitename}"
 
wget https://github.com/roundcube/roundcubemail/releases/download/1.3.8/roundcubemail-1.3.8-complete.tar.gz -O /tmp/roundcubemail-1.3.8-complete.tar.gz 2&gt;&gt; "${log}"
[ -e /tmp/roundcubemail-1.3.8-complete.tar.gz ] || {
echo "${errorprefix}/tmp/roundcubemail-1.3.8-complete.tar.gz not found - exiting"
exit 1
}
mkdir -p bup2"${httproot}"
[ -d "${roundcuberoot}" ] &amp;&amp; mv "${roundcuberoot}" bup2"${httproot}"
tar -C "${httproot}" -zxpf /tmp/roundcubemail-*.tar.gz
rm -f /tmp/roundcubemail-*.tar.gz
mv "${httproot}"/roundcubemail-* "${roundcuberoot}"
[ -d "${roundcuberoot}" ] || {
echo "${errorprefix}${roundcuberoot} not found - exiting"
exit 1
}
[ -e "${roundcuberoot}"/config/config.inc.php.sample ] || {
echo "${errorprefix}${roundcuberoot}/config/config.inc.php.sample not found - exiting"
exit 1
}
[ -d "${roundcuberoot}"/installer ] || {
echo "${errorprefix}${roundcuberoot}/installer not found - exiting"
exit 1
}
chown -R "${user}":www-data "${roundcuberoot}"
chmod -R 775 "${roundcuberoot}"/temp
chmod -R 775 "${roundcuberoot}"/logs
 
mkdir -p bup2/etc/apache2/sites-available
[ -e /etc/apache2/sites-available/"${roundcubesitename}" ] &amp;&amp; cp -a /etc/apache2/sites-available/"${roundcubesitename}" bup2/etc/apache2/sites-available/
 
sed -e "s/roundcubesitename/${roundcubesitename}/g;s/yourusername/${user}/g;s/yourdomain\.tld/${domain}/g" &lt;&lt; 'EOF' &gt; /etc/apache2/sites-available/"${roundcubesitename}"
 
ServerAdmin yourusername@yourdomain.tld
ServerName roundcubesitename.yourdomain.tld
EOF
 
sed -e "s/\/var\/www\/roundcube/$(echo ${roundcuberoot} | sed -e 's/\//\\\//g')/g" &lt;&lt; 'EOF' &gt;&gt; /etc/apache2/sites-available/"${roundcubesitename}"
DocumentRoot /var/www/roundcube
Options +FollowSymLinks
# AddDefaultCharset UTF-8
AddType text/x-component .htc
php_flag display_errors Off
php_flag log_errors On
# php_value error_log logs/errors
php_value upload_max_filesize 10M
php_value post_max_size 12M
php_value memory_limit 64M
php_flag zlib.output_compression Off
php_flag magic_quotes_gpc Off
php_flag magic_quotes_runtime Off
php_flag zend.ze1_compatibility_mode Off
php_flag suhosin.session.encrypt Off
#php_value session.cookie_path /
php_flag session.auto_start Off
php_value session.gc_maxlifetime 21600
php_value session.gc_divisor 500
php_value session.gc_probability 1
RewriteEngine On
RewriteRule ^favicon\.ico$ skins/larry/images/favicon.ico
# security rules:
# - deny access to files not containing a dot or starting with a dot
# in all locations except installer directory
RewriteRule ^(?!installer)(\.?[^\.]+)$ - [F]
# - deny access to some locations
RewriteRule ^/?(\.git|\.tx|SQL|bin|config|logs|temp|tests|program\/(include|lib|localization|steps)) - [F]
# - deny access to some documentation files
RewriteRule /?(README\.md|composer\.json-dist|composer\.json|package\.xml)$ - [F]
SetOutputFilter DEFLATE
# replace 'append' with 'merge' for Apache version 2.2.9 and later
# Header append Cache-Control public env=!NO_CACHE
ExpiresActive On
ExpiresDefault "access plus 1 month"
 
FileETag MTime Size
Options -Indexes
 
AllowOverride None
Order allow,deny
Allow from all
Options -FollowSymLinks
AllowOverride None
Order allow,deny
Deny from all
Options -FollowSymLinks
AllowOverride None
Order allow,deny
Deny from all
Options -FollowSymLinks
AllowOverride None
Order allow,deny
Deny from all
Options -FollowSymLinks
AllowOverride None
Order allow,deny
Deny from all
 
EOF
 
sed -e "s/roundcubesitename/${roundcubesitename}/g" &lt;&lt; 'EOF' &gt;&gt; /etc/apache2/sites-available/"${roundcubesitename}"
ErrorLog /var/log/apache2/error_roundcubesitename.log
 
# Possible values include: debug, info, notice, warn, error, crit,
# alert, emerg.
LogLevel warn
 
CustomLog /var/log/apache2/access_roundcubesitename.log combined
EOF
 
mkdir -p bup2/sql
mysqldump -u root -p"${mysqlrootpasswd}" 'roundcube' &gt; bup2/sql/roundcube.sql 2&gt;&gt; "${log}"
 
mysql --user=root --password="${mysqlrootpasswd}" -e "CREATE DATABASE IF NOT EXISTS `roundcube`;"
mysql --user=root --password="${mysqlrootpasswd}" -e "GRANT ALL PRIVILEGES ON `roundcube`.* TO 'roundcube'@'localhost' IDENTIFIED BY '${mysqlroundcubepasswd}';"
mysql --user=root --password="${mysqlrootpasswd}" -e "FLUSH PRIVILEGES;"
 
mysql -u root -p"${mysqlrootpasswd}" 'roundcube' &lt; "${roundcuberoot}"/SQL/mysql.initial.sql 2&gt;&gt; "${log}"
 
cp -a "${roundcuberoot}"/config/config.inc.php.sample "${roundcuberoot}"/config/config.inc.php
 
deskey=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9-_#&amp;!*%?' | fold -w 24 | head -n 1)
 
sed -e "s/mysqlroundcubepasswd/$(echo ${mysqlroundcubepasswd} | sed -e 's/\&amp;/\\\&amp;/g')/;s/roundcubeproductname/${roundcubeproductname}/;s/deskey/$(echo ${deskey} | sed -e 's/\&amp;/\\\&amp;/g')/;s/roundcubelanguage/${roundcubelanguage}/" &lt;&lt; 'EOF' &gt; "${roundcuberoot}"/config/config.inc.php
<!--?php                                                                                                                                                                                                               $config['db_dsnw'] = 'mysql://roundcube:mysqlroundcubepasswd@localhost/roundcube';                                                                                                                                  $config['log_driver'] = 'syslog';                                                                                                                                                                                   $config['default_host'] = 'ssl://localhost';                                                                                                                                                                        $config['default_port'] = 993;                                                                                                                                                                                      $config['smtp_server'] = 'ssl://localhost'; $config['smtp_port'] = 465; $config['smtp_user'] = ''; $config['smtp_pass'] = ''; $config['support_url'] = ''; $config['ip_check'] = true; $config['des_key'] = 'deskey'; $config['product_name'] = 'roundcubeproductname'; $config['plugins'] = array('archive','zipdownload'); $config['language'] = 'roundcubelanguage'; $config['enable_spellcheck'] = false; $config['mail_pagesize'] = 50; $config['draft_autosave'] = 300; $config['mime_param_folding'] = 0; $config['mdn_requests'] = 2; $config['skin'] = 'larry'; EOF rm -rf "${roundcuberoot}"/installer tmp="$(mktemp -t crontab.tmp.XXXXXXXXXX)" crontab -u "${user}" -l | sed "/$(echo ${roundcuberoot} | sed -e 's/\//\\\//g')\/bin\/cleandb\.sh/d" --> "${tmp}"
echo "18 11 * * * ${roundcuberoot}/bin/cleandb.sh &gt; /dev/null" &gt;&gt; "${tmp}"
crontab -u "${user}" "${tmp}"
rm -f "${tmp}"
unset tmp
 
a2enmod deflate
a2enmod expires
a2enmod headers
a2ensite "${roundcubesitename}"
service apache2 restart
 
## uninstall
echo '' &gt;&gt; "${log}"
echo 'uninstall roundcube using:' &gt;&gt; "${log}"
echo '' &gt;&gt; "${log}"
echo "mysql --user=root --password=yourpasswd -e \"DROP DATABASE \\`roundcube\\`;\"" &gt;&gt; "${log}"
echo "mysql --user=root --password=yourpasswd -e \"DROP USER 'roundcube'@'localhost';\"" &gt;&gt; "${log}"
echo "a2dissite ${roundcubesitename}" &gt;&gt; "${log}"
echo 'a2dismod expires' &gt;&gt; "${log}"
echo 'a2dismod headers' &gt;&gt; "${log}"
echo 'service apache2 restart' &gt;&gt; "${log}"
echo "rm /etc/apache2/sites-available/${roundcubesitename}" &gt;&gt; "${log}"
echo '' &gt;&gt; "${log}"
echo "remove the installation directory (${roundcuberoot})" &gt;&gt; "${log}"
 
echo ''
echo "check ${log} for erros"
