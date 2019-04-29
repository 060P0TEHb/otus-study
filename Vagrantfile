# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.provider "virtualbox" do |vb|
     vb.memory = "1024"
     vb.cpus = "8"
   end
  config.vm.provision "shell", inline: <<-SHELL
        sudo yum -y group install "Development Tools"
        sudo yum -y install wget openssl-devel elfutils-libelf-devel bc
        wget -P /home/vagrant/ https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.0.9.tar.xz
        tar -xf /home/vagrant/linux-5.0.9.tar.xz
        cd /home/vagrant/linux-5.0.9/
        sudo make olddefconfig
        sudo make -j $(nproc)
        sudo make modules_install
        sudo make install
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg
        sudo grubby --set-default /boot/vmlinuz-5.0.9
        rm /home/vagrant/linux-5.0.9.tar.xz
        rm -rf /home/vagrant/linux-5.0.9
        printf "\n\nDone\nby AcCkaYA sAtAnA"
        sleep 3
        sudo reboot
   SHELL
end
