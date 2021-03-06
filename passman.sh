#!/bin/bash

storage="$HOME/.passman.enc"
test -f "$HOME/.passman.conf" && . "$HOME/.passman.conf" 2>/dev/null
openssl_enc="openssl enc -aes256 -pbkdf2 -pass pass:\"\$p\" > $storage"
openssl_dec="openssl enc -d -aes256 -pbkdf2 -in $storage -pass pass:\"\$p\" 2>/dev/null"
ok='1'

gethash(){
	p=`echo $p | ( sha256sum || openssl sha256 -r ) | awk '{print $1}'`
}

readbase(){
    while [ "$ok" != '0' ] ; do
        read -r -s -p 'password:' p
	echo
	[ "$p" == "" ] && exit 0
        test=`eval "$openssl_dec"`
        ok=$?
	# try to decode with hash
	if [ "$ok" != "0" ]; then
		gethash
		test=`eval "$openssl_dec"`
		ok=$?
	fi
    done
}

makepass(){
    ok=''
    while [ "$ok" != 'true' ] ; do
        read -r -s -p 'new password:' p
        echo
	if [ -n "$p" ] ; then
            read -r -s -p 'repeat please:' p2
            echo
            [ "$p" == "$p2" ] && ok='true' || echo "Oops, there is misprint above, please try again."
	else
	    echo "zero input, password not changed"
	    break
	fi
    done
    gethash
    p2=""
}

confirm () {
    echo -en "$1"
    read -n 1 input
    echo
    case "$input" in
	y|Y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

newbase(){
    if confirm "\e[1;33mCreate new storage file? ([Y]es/[N]o)\e[0m" ; then
        makepass
        echo -n | eval "$openssl_enc"
        test=""
        printhelp
    fi
}

new_master_password(){
    if confirm "\e[1;33mChange password for existing storage file? ([Y]es/[N]o)\e[0m" ; then
        makepass
        [ -n "$test" ] && echo "$test" | eval "$openssl_enc"
    fi
}

printhelp(){
    echo "Commands:"
    echo "[h]elp"
    echo "[c]reate - create new database"
    echo "[n]ew master password"
    echo "[s]earch and show"
    echo "[l]ist records with less or just [p]rint list"
    echo "[a]dd or change record"
    echo "[d]elete record"
    echo "[q]uit"
    echo ""
}

test -f "$storage" && readbase || newbase
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
	l)
	    eval "$openssl_dec" | sort | cut -d\  -f 1 | less
	    ;;
	p)
	    eval "$openssl_dec" | sort | cut -d\  -f 1
	    ;;
        s)
	    read -r -p "Search for: " name
            echo "$test" | grep "$name"
	    ;;
	a)
            read -r -p "Add record name: " name
            name=`echo $name | cut -d' ' -f1`
            read -r -p "Type key for $name: " s
            testm=`echo "$test" | grep "^$name "`
            if [ -n "$testm" ] ; then
                if confirm "\e[1;33mAlready have record $name, replace it? ([Y]es/[N]o)\e[0m" ; then
                    test=`echo "$test" | sed "s/^$name\ .*$/$name $s/"`
                    echo "Replaced $name $oldp with $s"
                    [ -n "$test" ] && echo "$test" | eval "$openssl_enc"
                fi
            else
                test=`echo -e "$test\n$name $s"`
                echo "Added $name $s"
                [ -n "$test" ] && echo "$test" | eval "$openssl_enc"
            fi
            ;;
	d)
            read -r -p "Delete record name: " name
            testm=`echo "$test" | grep "^$name "`
            if [ -n "$testm" ] &&  [ -n "$name" ]; then
                if confirm "\e[1;33mDelete record $name? ([Y]es/[N]o)\e[0m" ; then
                        test=`echo "$test" | grep -v "^$name "`
                        [ -n "$test" ] && echo "$test" | eval "$openssl_enc"
                        echo "Deleted record $name"
                fi
            else
                    echo "There is no record $name"
	    fi
            ;;
	q)
	    clear
	    break
	    ;;
    esac
done

