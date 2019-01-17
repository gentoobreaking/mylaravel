#!/bin/bash

export my_project="mytestweb"
export git_src_1="git@gitlab.xxx.com:zzz/myweb.git" # web root
export git_src_2="git@gitlab.xxx.com:zzz/myweb-module1.git" # module
export git_src_3="git@gitlab.xxx.com:zzz/myweb-module2.git" # module
export git_src_1_folder="$(echo ${git_src_1}|awk -F'/' '{print $NF}')"
export git_src_2_folder="$(echo ${git_src_1}|awk -F'/' '{print $NF}')"
export git_src_3_folder="$(echo ${git_src_1}|awk -F'/' '{print $NF}')"

BUILD_IMAGE()
{
export my_version='v0.1'
docker build -t "${my_project}":"${my_version}" . --no-cache
}

Preparation()
{
echo "Preparation for ${my_project}."

if [ ! -d ./"${git_src_1_folder}" ]
then
  echo " - git clone ${git_src_1}"
  git clone "${git_src_1}"
  git checkout dev
  git branch
  [ ! -d ./"${git_src_1_folder}"/Modules ] && mkdir "${git_src_1_folder}"/Modules
  cd ./"${git_src_1_folder}"/Modules/
  if [ ! -d ./"${git_src_2_folder}" ]
  then
    echo " - git clone ${git_src_2}"
    git clone "${git_src_2}"
    cd ./"${git_src_2_folder}"
    git checkout dev
    git branch
    cd ..
  fi
  if [ ! -d ./"${git_src_3_folder}" ]
  then
    echo " - git clone ${git_src_3}"
    git clone "${git_src_3}"
    cd ./"${git_src_3_folder}"
    git checkout dev
    git branch
    cd ..
  fi
  cd ../..
else
  echo " - update from ${git_src_1}"
  cd ./"${git_src_1_folder}"
  git push
  git checkout dev;git branch
  cd ..
  echo " - update from ${git_src_2}"
  cd ./"${git_src_1_folder}"/Modules/"${git_src_2_folder}"/
  git push
  git checkout dev;git branch
  cd ../../../
  echo " - update from ${git_src_3}"
  cd ./"${git_src_1_folder}"/Modules/"${git_src_3_folder}"/
  git push
  git checkout dev;git branch
  cd ../../../
fi
}

Deploy()
{
echo "Deploy for ${my_project}."
docker-compose up -d
docker-compose ps
}

Create_DataBase()
{
export MY_DB="xxxdb"
export MY_IP="$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${my_project})"
echo "myweb ip address:${MY_IP}"
echo " - Please waitting for 10 secs avoiding mysql service doesn't startup finish."
sleep 10
docker exec -i "${my_project}" mysql -u root -ppassword -h mysql <<EOF
CREATE DATABASE ${MY_DB};
GRANT ALL PRIVILEGES ON ${MY_DB}.* TO 'admin'@'${MY_IP}' IDENTIFIED BY 'admin';
exit;
EOF
}

Post_Steps()
{
docker cp ./.env "${my_project}":/www/.env
docker exec -i "${my_project}" /bin/bash << EOF
mkdir -p /var/log/nginx/
chown -R www:www /www/public /www/storage /www/bootstrap
chmod -R 777 /www/public /www/storage /www/bootstrap
cd /www
composer install
php artisan cache:clear
php artisan migrate:fresh
echo " - clear cache."
rm -rf /www/resources/reactViews/themes/default/src/modules/*
npm install
#npm run dev
npm run prod
EOF
}

Show_Menu()
{
echo " - Please input the action: (the following lines have be order.)"
echo "   b | build_image : Build container image."
echo "   p | preparation : Preparation for getting source codes."
echo "   d | deploy : Deploy for containeri(s)."
echo "   c | create_dataBase : Create dataBase(s)."
echo "   o | post_steps : Do some post steps for service startup."
echo "   a | all : Do the all action in one time."
}

My_Menu()
{
Show_Menu
while :
do
  read INPUT_STRING
  case $INPUT_STRING in
	b|build_image)
		echo "Build container image."
		BUILD_IMAGE
		Show_Menu
		;;
	p|preparation)
		echo "Preparation for getting source codes."
		Preparation
		Show_Menu
		;;
	d|deploy)
		echo "Deploy for containeri(s)."
		Deploy
		Show_Menu
		;;
	c|create_dataBase)
		echo "Create database(s)."
		Create_DataBase
		Show_Menu
		;;
	o|post_steps)
		echo "Do some post steps for service startup."
		Post_Steps
		Show_Menu
		;;
	a|all)
		echo "Do the all action in one time."
		BUILD_IMAGE
		Preparation
		Deploy
		Create_DataBase
		Post_Steps
		break
                ;;
	*)
		echo "Sorry, I don't understand. So quit."
		break
		;;
  esac
done
echo 
echo "That's all!"
}

My_Menu

# --- END --- #
