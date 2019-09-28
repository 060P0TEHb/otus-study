#!/bin/bash

print_help(){
  printf "print\n  --root for set mail box (example --root some-box@gmail.com)\n  --hub for set mailhub (example --hub smtp.gmail.com:587)\n"
  exit 0
}

#Check input
if [[ $# -eq 4 ]]
then
  while [[ $# -gt 0 ]]
  do
    key="$1"
    case $key in
      #Set mail root
      --root) 
        MAIL_ROOT="$2"
        shift
        shift
      ;;
      #Set mail hub
      --hub)
        MAIL_HUB="$2"
        shift
        shift
      ;;
      #Other
      *)
         print_help
         shift
      ;;
    esac
  done
else
  print_help
fi

###
# Main
###

if (set -C; echo "$$" > "$(dirname $0)/$0-lockfile") 2>/dev/null; then
  trap 'rm -f "$(dirname $0)/$0-lockfile"; exit $?' INT TERM EXIT

    #Clear workspace
    echo "delete vm"
    vagrant halt 1>/dev/null 2>/dev/null
    vagrant destroy -f 1>/dev/null 2>/dev/null
    
    #Create vagrant file
    echo "create vm"
    cat > Vagrantfile << EOF

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "512"
    vb.cpus = "1"
  end
  
  config.vm.provision "shell", inline: <<-SHELL
    sudo yum install epel-release -y
    sudo yum install mailx ssmtp ntpdate -y
    sudo ntpdate pool.ntp.org
    sudo timedatectl set-timezone Europe/Moscow
  SHELL
end
EOF
    
    #Start VM
    echo "start vm"
    vagrant up 1>/dev/null
    
    #Change config
    echo "start tasks"
    SSH_CONNECT="ssh -o LogLevel=QUIET -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i $(find . -name 'private_key') -p $(vagrant ssh-config | grep Port | awk '{print $(NF)}') vagrant@localhost"
    
    $SSH_CONNECT 'sudo sed -i "s/^root=.*/root='$MAIL_ROOT'/g" /etc/ssmtp/ssmtp.conf'
    $SSH_CONNECT 'sudo sed -i "s/^mailhub=.*/mailhub='$MAIL_HUB'/g" /etc/ssmtp/ssmtp.conf'
    
    $SSH_CONNECT 'awk "/##!\/bin\/bash/,/EOF/" /vagrant/script.sh | sed "s/^#//g" > /vagrant/work-script.sh'
    $SSH_CONNECT 'rm /vagrant/script.sh /vagrant/Vagrantfile /vagrant/script.sh-lockfile'

    $SSH_CONNECT 'printf "* * * * * /bin/head -n100 /vagrant/nginx.log >> /vagrant/nginx-send.log && /bin/sed -i \"1,100d\" /vagrant/nginx.log\n* * * * * sleep 30; bash /vagrant/work-script.sh -f /vagrant/nginx-send.log 2>/dev/null | mail -r AcCkAyA_SoToNa@from.hell -E -s \"Nginx Statistics (HomeWork)\" $(sudo grep root /etc/ssmtp/ssmtp.conf | cut -d= -f2)\n" | crontab -' 
    

 rm -f "$(dirname $0)/$0-lockfile"
 trap - INT TERM EXIT
 echo "All done. Check $MAIL_ROOT for new letters (Maybe in spam)"

else
   echo "Can't create lock file"
   echo "Hold by $(cat /tmp/$(basename $LOG_PATH).lockfile)"
fi


##!/bin/bash
#
#print_help(){
#  echo "print -f <path> or --file <path> and set path to log"
#  exit 0
#}
#
##ip count
#custom_out() {
#    sort | uniq -c | sort -nrk1 | head
#}
#
#print_data() {
#    if [[  -f $LOG_PATH.offset ]]; then
#       echo "$(tail -n1 $LOG_PATH.offset | cut -d' ' -f1) $(date +%d.%m.%Y-%H:%M:%S)" 
#    else
#       echo "New file - start watching at $(date +%d.%m.%Y-%H:%M:%S)"
#    fi
#}
#
#
#if [[ $# == 0 ]]; then
#  print_help
#fi
#
#
#while [[ $# -gt 0 ]]
#do
#key="$1"
#
#case $key in
#    #Set log file
#    -f|--file)
#      LOG_PATH="$2"
#        #Check file exist
#        if [[ ! -f $LOG_PATH ]];then
#            >&2 echo "file not found" 
#            exit 1
#        fi
#      shift
#      shift
#    ;;
#    #Other
#    *)
#       print_help
#       shift
#    ;;
#  esac
#done 
#
#if (set -C; echo "$$" > "/tmp/$(basename $LOG_PATH).lockfile") 2>/dev/null
#then
# trap 'rm -f "/tmp/$(basename $LOG_PATH).lockfile"; exit $?' INT TERM EXIT
#   #Check file start from offset
#   if [[  -f $LOG_PATH.offset ]]; then 
#       START_LINE=$(tail -n1 $LOG_PATH.offset | cut -d' ' -f2)
#       TOP_IP="$( tail -n +$START_LINE $LOG_PATH| awk '{print $1}' | custom_out )"
#       ANSWER="$( tail -n +$START_LINE $LOG_PATH| awk -F '"' '{print $3}' | cut -d' ' -f2 | sort | uniq -c)"
#       IFS=$'\n'
#       for i in $(tail -n +$START_LINE $LOG_PATH| grep "\" [4-5][0-9][0-9] " | grep -v 404); do
#         ERROR_STRING+=($i)
#       done
#   #Start from begin file
#   else
#       TOP_IP="$( awk '{print $1}' $LOG_PATH | custom_out )"
#       ANSWER="$( awk -F '"' '{print $3}' $LOG_PATH | cut -d' ' -f2 | sort | uniq -c)"
#       IFS=$'\n'
#       for i in "$(grep "\" [4-5][0-9][0-9] " $LOG_PATH | grep -v 404)"; do
#         ERROR_STRING+=($i)
#       done
#   fi
#
#   #Print result
#   if [[ -z $TOP_IP ]];then
#      >&2 echo "File not change"
#      exit 0
#   else
#      print_data
#      printf "\nTOP IP:\n$TOP_IP\n\nANSWER:\n$ANSWER\n\n"
#      printf "Errors:\n"
#      for ((i=0;i<${#ERROR_STRING[@]};i++));do 
#        echo ${ERROR_STRING[i]}
#      done
#   fi
#
#   #Write offset
#   echo $(date +%d.%m.%Y-%H:%M:%S) $(($(wc -l $LOG_PATH  | awk '{print $1}')+1)) >> $LOG_PATH.offset
#
# rm -f "/tmp/$(basename $LOG_PATH).lockfile"
# trap - INT TERM EXIT
#
#else
#   echo "Can't create lock file"
#   echo "Hold by $(cat /tmp/$(basename $LOG_PATH).lockfile)"
#fi
