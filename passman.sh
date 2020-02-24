#!/bin/bash

basename='c.stuff'
openssl_enc="openssl enc -aes256 -pbkdf2 -pass pass:\"\$p\" > $basename"
openssl_dec="openssl enc -d -aes256 -pbkdf2 -in $basename -pass pass:\$p 2>/dev/null"
ok='1'
readbase(){
    while [ $ok != '0' ] ; do
        read -s -p 'password:' p
        echo
        test=`eval "$openssl_dec"`
        ok=$?
    done
}
makepass(){
    ok=''
    while [ "$ok" != 'true' ] ; do
        read -s -p 'new password:' p
        echo
	if [ -n "$p" ] ; then
            read -s -p 'repeat please:' p2
            echo
            [ "$p" == "$p2" ] && ok='true' || echo "Oops, there is misprint above, please try again."
	else
	    echo "zero input, password not changed"
	    break
	fi
    done
}
newbase(){
    echo "Creating new database"
    makepass
    echo -n | eval "$openssl_enc"
    test=""
}
new_master_password(){
    echo "Creating new password for existing database."
    makepass
    [ -n "$test" ] && echo "$test" | eval "$openssl_enc"
}
printhelp(){
    echo "Commands:"
    echo "[h]elp"
    echo "[c]reate - create new database"
    echo "[n]ew master password"
    echo "[s]how - show item"
    echo "[l]ist or [p]rint all items"
    echo "[a]dd or change item"
    echo "[d]elete item"
    echo "[q]uit"
    echo ""
}

test -f $basename && readbase || newbase
printhelp

while : ; do
    read -n 1 -p "command: " input
    echo
    case "$input" in
	h)
            printhelp
            ;;
	c)
            newbase
            ;;
        n)
	    new_master_password
            ;;
	l|p)
	    eval "$openssl_dec"
	    ;;
        s)
	    read -p "type name: " name
            echo "$test" | grep "^$name\ " | sed "s/^$name\ //g"
	    ;;
	a)
            read -p "type name: " name
            name=`echo $name | cut -d' ' -f1`
            read -p "type key for $name: " string
            # screen '&' and '/' symbols 
            s=`echo "$string" | sed -e 's/[\&\/]/\\\&/g'`
            testm=`echo "$test" | grep "^$name "`
            if [ -n "$testm" ] ; then
                test=`echo "$test" | sed "s/^$name\ .*$/$name $s/"`
            else
                test=`echo "$test" | sed "$ a$name $s"`
            fi
            echo "$name $oldp > $string"
            [ -n "$test" ] && echo "$test" | eval "$openssl_enc"
            ;;
	d)
            read -p "type name: " name
            testm=`echo "$test" | grep "^$name "`
            if [ -n "$testm" ] &&  [ -n "$name" ]; then
                test=`echo "$test" | grep -v "^$name "`
#		[ -n "$test" ] && echo "$test" | openssl enc -aes256 -pbkdf2 -pass pass:"$p" > $basename

		[ -n "$test" ] && echo "$test" | eval "$openssl_enc"
	        echo "deleted item $name"
	    fi
            ;;
	q)
	    clear
	    break
	    ;;
    esac
done

