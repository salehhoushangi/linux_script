#!/bin/sh
####checking feed up script with a file#######
now=$(date +"%m_%d_%Y")
Lua_file="allowedUsers.lua"
Lua_file_path="/usr/local/openresty/nginx/"
Lua_Backup="/opt/Lua_backup/"
Lua_problem="/opt/Lua_problem/"
Lua_Git="/opt/Lua_Git/"
Git_Repo=" https://bitbucket.dotin.ir/scm/it/test-jira.git"
Git_dir="test-jira/"
_file="$1"
_issue="$2" #issue number from customer request or date of request %m_%d_%Y
#re='^[0-9]+$'

######checking file existence ##########

[ $# -eq 0 ] && { echo " Usage : $0 filename  issue_number"; exit 1; }

[ ! -f "$_file" ] && { echo "Error: $0 can not find file "$1"."; exit 1; }
[ ! -s "$_file" ] && { echo "Error: file $1 is empty."; exit 1; }
[ -z "$_issue" ] && { echo "Error:  issue number not found."; exit 1; }
PS3="Please Enter one of these branch you want to push it ( 1 or 2 or 3): "
options=("proxy1" "proxy2" "master")
select opt in "${options[@]}"
do
    case $opt in 
         "proxy1")
              echo "you chose proxy1 branch"
              break
          ;;
          "proxy2")
              echo "you chose proxy2 branch"
              break
          ;;
          "master")
              echo "you chose $REPLY which is $opt"
              break
          ;;   
           *) echo "invalid branch $REPLY" ;;
     esac
done

branch_name=$opt
#re='^[0-9]+$'
[ ! -d "$Lua_Backup" ] && { echo "backup directory Not exit, making backup directory in  $Lua_backup" && mkdir -p $Lua_Backup; }
#[ ! -d "$Lua_Git" ] && { echo "Directory to sending lua file to Git_Repository Not exit, making git  directory in  $Lua_Git" && mkdir -p $Lua_Git; }
######select branch of repository##
if [ -f "$_file" ] 

then 
    
   cp $Lua_file_path$Lua_file  $Lua_Backup
  
   echo "Backup done in $Lua_Backup"

   sed -i  '/^$/d' $_file  && sed -i -e 's/^[ \t]*//' $_file

   echo "$1 file purging done"

    while IFS= read -r line
   
    do
    
       #echo "$line"
       user_exist=`grep -F "$line" $Lua_file_path$Lua_file`

       if [ $? -eq 0 ]; then 


          echo "$line exsit in allowUsers.lua file"


          continue

       else

       echo "$line added to $Lua_file"  
       sed -i  '/and (val ~= "anonymous")/ i\ \ \ \ \ \ \ \ \ \ \ \ \ \   and (val ~= "'$line'")' $Lua_file_path$Lua_file  ### inset file line by line to allowUsers.lua file
        New_id=1
       fi
    done < "$_file"

    if [[ $New_id = 1 ]] ; then 

         openresty -t  2> /dev/null
    else 

       echo "All user is exist so Nothing to do"
       exit 0
    fi
    
    if [ $? -eq 0 ]; then
    
        openresty -s reload 
        echo "openresty service RELOADED"
      if [ ! -d $Lua_Git ]; then  
       
            git clone --branch $branch_name $Git_Repo  $Lua_Git 
        
      elif [ -d $Lua_Git ]; then 
        
        cd $Lua_Git
        git checkout $opt
        wait 4 
        cp $Lua_file_path$Lua_file .
        git add --all
        git commit  -m "$_issue"
        git push 
      fi         

    else 
  
       openresty -t 
       echo "somting wrong with openresty configuration"
     
       [ ! -d $Lua_problem ] && { mkdir -p $Lua_problem; }
       
       cp $Lua_file_path$Lua_file  $Lua_problem$Lua_file_$now
      
       cp $Lua_Backup$Lua_file  $Lua_file_path

       echo " allowedUsers.lua restored  to the last state before change"
       
       exit 1
    fi 
    
   
 


else 

    echo "$_file not exsit."

fi    
  
