#!/bin/bash
set -e

echo "------------------------------------------| Wait for it... Wait for it... mariadb is starting"
for i in {10..0}; do
  echo "------------------------------------------| mariadb-server container is initalizing.... $i "
  files=$(mysql -uroot -h db -e "GRANT USAGE ON *.* TO ping@'%' IDENTIFIED BY 'ping';")
  if [ $? == 0 ]; then
    echo "------------------------------------------| Creating  DB Drupal user & DB, Clean up DB"
    sleep 3
    mysql -uroot -h db -e "FLUSH PRIVILEGES ;"
    #mysql -uroot -h db -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;"
    mysql -uroot -h db -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;"
    mysql -uroot -h db -e "GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
    mysql -uroot -h db -e "FLUSH PRIVILEGES ;"
    # mysql -uroot -h db -e "SELECT User FROM mysql.user ;"
    # mysql -uroot -h db -e "SHOW DATABASES;"
    break
  fi
      sleep 1
      continue
done

echo "------------------------------------------| Fix Nginx for Drupal"
rm -rf /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sed -i 's=;cgi.fix_pathinfo\=1=cgi.fix_pathinfo\=0=g' /etc/php5/fpm/php.ini
mkdir -p /files/config/
wget https://raw.githubusercontent.com/mugithi/egs-drupal-template/master/files/config/default -O  /files/config/default
wget https://raw.githubusercontent.com/mugithi/egs-drupal-template/master/files/config/www.conf -O /files/config/www.conf
cp /files/config/default /etc/nginx/sites-available/default
cp /files/config/www.conf /etc/php5/fpm/pool.d/www.conf


echo "------------------------------------------| Install Drupal Content Management System"
cd /usr/share/nginx/
rm -rf html/
drush dl drupal --drupal-project-rename=html
cd html/
drush site-install -y standard --account-name=$DRUPAL_USER --account-pass=$DRUPAL_PASSWORD --db-url=mysql://$MYSQL_USER:$MYSQL_PASSWORD@db/$MYSQL_DATABASE --site-name=isaack.io

echo "------------------------------------------| Selectively Restore files from github"

############################ Uncomment elements below if a site already exisits ############################
#Clone github
#rm -rf /files/config/site
#mkdir /files/config/site
#cd /files/config/site
#git clone $git_repo .
#git remote add gh_remote $git_repo .

#Restore Sites all
#rm -rf /usr/share/nginx/html/sites/all/
#mkdir /usr/share/nginx/html/sites/all/
#mv /files/config/site/sites/all/* /usr/share/nginx/html/sites/all/

#Restore sites default with overwrite
#cp -nR /files/config/site/sites/default/* /usr/share/nginx/html/sites/default/
#chown -R www-data:www-data /usr/share/nginx/html/

#Replace install modules
#rm -rf /usr/share/nginx/html/modules
#mkdir /usr/share/nginx/html/modules
#mv /files/config/site/modules/* /usr/share/nginx/html/modules

#Put in the python executables
#mkdir /usr/share/nginx/html/EXEC/
#mv /files/config/site/EXEC/* /usr/share/nginx/html/EXEC/

echo "------------------------------------------| Restore database"
#mysql -u root -h db --database drupal </files/config/site/sql_dump/file.sql

############################ END OF UNCOMMENT SITE RESTORE SECTION ########################################

echo "------------------------------------------| Start php5-fsm And check for any fault status before layer is closed"
service php5-fpm start

echo "------------------------------------------| Restart Nginx And check for any fault status before layer is closed"
service nginx restart

echo "------------------------------------------| Tailing logs"
tail -f /var/log/nginx/error.log

