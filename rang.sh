##created by houshangi @ respina in 2019#####
function record_type(){
read recordtype
recordtype=`echo $recordtype | tr [a-z] [A-z]`
while true; do
        if ! [[ "$recordtype" = "MX" || "$recordtype" = "PTR" || "$recordtype" = "A" ]]; then  echo 'your input type is not valid, Enter valid format(PTR,A,MX...)!:' && record_type
        else  break;

        fi
done

}
function main_range(){
read ip
while true; do
        if ! [[ $ip =~ ^[0-9]{1,3}+\.[0-9]{1,3}+\.[0-9]{1,3}+$ ]]; then echo "your format is wrong. please enter correct format :!" && main_range
        else break;
        fi
done
}
function record_name(){

read record
while true; do
        if ! [[ $record =~ ^[a-z]+\.[a-z]+\.[a-z]+$ ]]; then echo "you are out of band, enter your domain and subdomain again:" && record_name
        else break;
        fi
done

}
echo "##################WELCOME TO ADD RANGE IP #############################"
echo " "
echo "Enter your record name(ex:mail.exam.com):"
record_name
echo "Enter your Record Type(ex:ptr/A/MX..):"
record_type
echo "Enter the first three parts of ip(ex:10.1.2):"
main_range
while true; do
        echo "Enter the range of you want to create. {from:  To:}"
        echo "from:"
        read var2
    if ! [[ "$var2" =~ ^-?[0-9]+$ ]]; then echo 'Error: Not an integer' >&2
    elif (( $var2 <= 0   ));           then echo 'Error: Need positive integers' >&2
    elif [[ "$var2" =~ ^-?[0-9]+$ ]]; then break;
    fi
done
while true; do
        echo "To:"
        read var3
    #if [[ "$var3" <= "$var2" ]]; then echo 'Erro: from(number) can not less than To(number)' && exit
    #fi
    if ! [[ "$var3" =~ ^-?[0-9]+$ ]]; then echo 'Error: Not an integer' >&2
    elif (( $var3 <= 0   ));           then echo 'Error: Need positive integers >0' >&2
    elif [[ "$var3" =~ ^-?[0-9]+$ ]]; then break;
    fi
done
#if [[ "$var3" <= "$var2" ]]; then echo 'Erro: from(number) can not less than To(number)' && exit
#fi

echo "############### RANG for $var1.global.rev####################" > out_range.txt
for ((c=$var2 ; c<=$var3 ; c++))
do
        echo -e  $c  '\t''\t''\t' "${recordtype^^}" '\t' $record.  >> out_range.txt
done
echo "RANGE succefully created in /opt/out_range.txt"
cat /opt/out_range.txt
