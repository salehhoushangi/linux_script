#!/bin/bash
# 

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    
    echo " use findzip -k(keyword) -p(path_file) -f(format)"
    
    exit 1
fi
while  getopts k:p:f: flag 
do 
   case "${flag}" in 
        k) keyword=${OPTARG};;
    
        p) path_file=${OPTARG};;
    
        f) format=${OPTARG};;
   
   esac
done
 if [[ $format == "zip" ]]; then 
 for x in `find $path_file -name *$format`;
    
       do   value=`unzip -p  $x 2>/dev/null`  
     
          machted_str=`echo $value | grep -c "$keyword"`  
     
          if [[ $machted_str == 1 ]] ; then 
           
          
            echo "matched in ziiped file: $x"
            #echo "keyword find in :`unzip -l $x  | grep -nRi "$keyword"`"
          
         fi 
 done
 else
echo "We are going to find your string $Keyword in plane Text file:"
grep -rnwo $path_file -e $keyword
  fi