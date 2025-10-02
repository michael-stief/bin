#!/bin/bash

g='\033[0;32m'
l='\033[0;35m'
c='\033[0;36m'
r='\033[0;31m'
y='\033[0;33m'
n='\033[0m'

function has-space {
  [[ "$1" != "${1%[[:space:]]*}" ]] && return 0 || return 1
}

function usage {
	echo -e "Usage: ${y}$(basename "$0") ${l}[server] ${g}[domain] ${c}[repo]${n}"
	echo
	echo -e "Example: ${y}$(basename "$0") ${l}dev ${g}example.com ${c}git@git.apps.lu:foo/bar.git${n}"
	exit 1
}

function error {
	echo -e "$1"
	exit 2
}

function check {
	[[ $1 -gt 0 ]] && error "${r}failed${n}" || echo -e "${g}OK${n}"
}

if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then
	echo -e "${r}error: arguments missing${n}"
	echo
	usage
fi
[[ ! -z $4 ]]  && error "too many argumeunts"
has-space "$1" && error "no spaces allowed in server"
has-space "$2" && error "no spaces allowed in domain"
has-space "$3" && error "no spaces allowed in repo"

server=$1
url=$2
repo=$3
dbpass=$(LC_ALL=C tr -dc bcdfghjkmpqrtvwxyzCDFGHJKMPQRTVWXYZ234679 < /dev/urandom | head -c16)

echo -en "${c}Try to connect to ${server} server: ${n}";         ssh $server true 1>/dev/null 2>/dev/null; check $?
echo -en "${c}Check for Apache config conflict: ${n}";           ssh $server ! test -e "/etc/apache2/sites-available/$url.conf"; check $?
echo -en "${c}Create Apache2 config: ${n}";                      ssh $server "echo PFZpcnR1YWxIb3N0ICo6NDQzPgoJU2VydmVyTmFtZSBSRVBMQUNFX01FCglTZXJ2ZXJBZG1pbiB3ZWJtYXN0ZXJAYXBwcy5sdQoJRG9jdW1lbnRSb290IC92YXIvd3d3L1JFUExBQ0VfTUUvcHVibGljCglFcnJvckxvZyAke0FQQUNIRV9MT0dfRElSfS9SRVBMQUNFX01FLmVycm9yLmxvZwoJQ3VzdG9tTG9nICR7QVBBQ0hFX0xPR19ESVJ9L1JFUExBQ0VfTUUuYWNjZXNzLmxvZyBjb21iaW5lZAoKCVNTTEVuZ2luZSBvbgoJU1NMQ2VydGlmaWNhdGVGaWxlICAgICAgL2V0Yy9sZXRzZW5jcnlwdC9saXZlL1JFUExBQ0VfTUUvZnVsbGNoYWluLnBlbQoJU1NMQ2VydGlmaWNhdGVLZXlGaWxlICAgL2V0Yy9sZXRzZW5jcnlwdC9saXZlL1JFUExBQ0VfTUUvcHJpdmtleS5wZW0KCgk8RmlsZXNNYXRjaCBcLnBocD4KCQlTZXRIYW5kbGVyICJwcm94eTp1bml4Oi92YXIvcnVuL3BocC9waHA4LjItZnBtLnNvY2t8ZmNnaTovL2xvY2FsaG9zdC8iCgk8L0ZpbGVzTWF0Y2g+CjwvVmlydHVhbEhvc3Q+Cg== | base64 -d | sudo tee /etc/apache2/sites-available/$url.conf >/dev/null"; check $?
echo -en "${c}Replace placeholders with $url: ${n}";             ssh $server "sudo sed -i \"s/REPLACE_ME/$url/g\" /etc/apache2/sites-available/$url.conf"; check $?
echo -en "${c}Get certificate: ${n}";                            ssh $server "sudo certbot certonly --webroot -n -w /var/www/html -d $url >/dev/null 2>&1"; check $?
echo -en "${c}Enable website in Apache: ${n}";                   ssh $server "sudo a2ensite $url >/dev/null"; check $?
echo -en "${c}Reload Apache service: ${n}";                      ssh $server "sudo systemctl reload apache2 >/dev/null"; check $?
echo -en "${c}Create /var/www/$url: ${n}";                       ssh $server "sudo mkdir -m 777 /var/www/$url"; check $?
echo -en "${c}Clone repo: ${n}";                                 ssh $server "sudo -u deploy git clone $repo /var/www/$url >/dev/null 2>&1"; check $?
echo -en "${c}Set group for /var/www/$url: ${n}";                ssh $server "sudo find /var/www/$url -exec chgrp www-data '{}' +"; check $?
echo -en "${c}Set group permission for /var/www/$url: ${n}";     ssh $server "sudo find /var/www/$url -exec chmod g+rwx '{}' + "; check $?
echo -en "${c}Set other permission for /var/www/$url: ${n}";     ssh $server "sudo find /var/www/$url -exec chmod o-rwx  '{}' + "; check $?
echo -en "${c}Create database $url: ${n}";                       ssh $server "sudo -u mysql mysql -e 'CREATE DATABASE \`${url}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;'"; check $?
echo -en "${c}Create database user $url ${n}";                   ssh $server "sudo -u mysql mysql -e \"CREATE USER '${url}'@'localhost';\""; check $?
echo -en "${c}Set password for $url to ${l}${dbpass}${c}: ${n}"; ssh $server "sudo -u mysql mysql -e \"SET PASSWORD FOR '${url}'@'localhost' = PASSWORD('${dbpass}'); FLUSH PRIVILEGES;\""; check $?
echo -en "${c}Looking for composer.lock: ${n}";                  ssh $server "test -e /var/www/$url/composer.lock"
if [[ $? -eq 0 ]]; then
  echo -e "${g}found${n}"
  echo -en "${c}Composer install: ${n}";                         ssh $server "cd /var/www/$url && composer -q install >/dev/null"; check $?
  echo -en "${c}Copy .env.example to .env: ${n}";                ssh $server "cd /var/www/$url && cp .env.example .env"; check $?
  echo -en "${c}Generate app key: ${n}";                         ssh $server "cd /var/www/$url && php artisan key:generate >/dev/null"; check $?
else
  echo -e "${r}not found${n}"
  echo -en "${c}Removing /public from DocumentRoot: ${n}";       ssh $server "sudo sed -i '/^[[:space:]]*DocumentRoot/s|/public||' /etc/apache2/sites-available/$url.conf"; check $?
  echo -en "${c}Reloading Apache serivce: ${n}";                 ssh $server "sudo systemctl reload apache2 >/dev/null"; check $?
fi
echo -e "${l}Successfully reached end of script \(^.^)/${n}"
