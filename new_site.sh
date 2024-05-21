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
	echo -e "Example: ${y}$(basename "$0") ${l}dev ${g}foo.bar ${c}\"https://x-token-auth:XXXB@bitbucket.org/apps-lu/XXX.git\"${n}"
	exit 1
}

function error {
	echo -e "$1"
	exit 2
}

function check {
	[[ $1 -gt 0 ]] && error "${r}failed${n}" || echo -e "${g}OK${c}"
}

if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]]; then
	echo -e "${r}error: arguments missing${n}"
	echo
	usage
fi
[[ ! -z $4 ]]  && error "too many argumeunts"
has-space "$1" && error "no spaces allowed in server"
has-space "$2" && error "no spaces allowed in domain"
has-space "$3" && error "no spaces allowed in bitbucket"

server=$1
url=$2
repo=$3

echo -en "${c}Try to connect to ${server} server: ${c}"; ssh $server true 1>/dev/null 2>/dev/null; check $?
echo -en "${c}Check for Apache config conflict: ${c}";   ssh $server ! test -e "/etc/apache2/sites-available/$url.conf"; check $?
echo -en "${c}Create Apache2 config: ${c}";              ssh $server "echo PFZpcnR1YWxIb3N0ICo6NDQzPgoJU2VydmVyTmFtZSBSRVBMQUNFX01FCglTZXJ2ZXJBZG1pbiB3ZWJtYXN0ZXJAYXBwcy5sdQoJRG9jdW1lbnRSb290IC92YXIvd3d3L1JFUExBQ0VfTUUvcHVibGljCglFcnJvckxvZyAke0FQQUNIRV9MT0dfRElSfS9SRVBMQUNFX01FLmVycm9yLmxvZwoJQ3VzdG9tTG9nICR7QVBBQ0hFX0xPR19ESVJ9L1JFUExBQ0VfTUUuYWNjZXNzLmxvZyBjb21iaW5lZAoKCVNTTEVuZ2luZSBvbgoJU1NMQ2VydGlmaWNhdGVGaWxlICAgICAgL2V0Yy9sZXRzZW5jcnlwdC9saXZlL1JFUExBQ0VfTUUvZnVsbGNoYWluLnBlbQoJU1NMQ2VydGlmaWNhdGVLZXlGaWxlICAgL2V0Yy9sZXRzZW5jcnlwdC9saXZlL1JFUExBQ0VfTUUvcHJpdmtleS5wZW0KCgk8RmlsZXNNYXRjaCBcLnBocD4KCQlTZXRIYW5kbGVyICJwcm94eTp1bml4Oi92YXIvcnVuL3BocC9waHA4LjItZnBtLnNvY2t8ZmNnaTovL2xvY2FsaG9zdC8iCgk8L0ZpbGVzTWF0Y2g+CjwvVmlydHVhbEhvc3Q+Cg== | base64 -d | sudo tee /etc/apache2/sites-available/$url.conf >/dev/null"; check $?
echo -en "${c}Replace placeholders with $url: ${c}";     ssh $server "sudo sed -i \"s/REPLACE_ME/$url/g\" /etc/apache2/sites-available/$url.conf"; check $?
echo -en "${c}Get certificate: ${c}";                    ssh $server "sudo certbot certonly --webroot -n -w /var/www/html -d $url >/dev/null 2>&1"; check $?
echo -en "${c}Enable website in Apache: ${c}";           ssh $server "sudo a2ensite $url >/dev/null"; check $?
echo -en "${c}Reload Apache service: ${c}";              ssh $server "sudo systemctl reload apache2 >/dev/null"; check $?
echo -en "${c}Create /var/www/$url: ${c}";               ssh $server "mkdir /var/www/$url"; check $?
echo -en "${c}Clone repo: ${c}";                         ssh $server "cd /var/www/$url && git clone $repo . >/dev/null 2>&1"; check $?
echo -en "${c}Composer install: ${c}";                   ssh $server "cd /var/www/$url && composer -q install >/dev/null"; check $?
echo -en "${c}Composer update: ${c}";                    ssh $server "cd /var/www/$url && composer -q update >/dev/null"; check $?
echo -en "${c}Copy .env.example to .env: ${c}";          ssh $server "cd /var/www/$url && cp .env.example .env"; check $?
echo -en "${c}Generate app key: ${c}";                   ssh $server "cd /var/www/$url && php artisan key:generate >/dev/null"; check $?
echo -e "${g}End of script reached without exiting \o/"
