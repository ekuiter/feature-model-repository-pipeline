# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
   vb.memory = "8192"
  end

  config.vm.define "kconfigreader" do |kconfigreader|
    kconfigreader.vm.box = "ubuntu/trusty64"
    kconfigreader.vm.provision "shell", privileged: false, inline: "cd /vagrant; source setup_kconfigreader.sh"
  end

  config.vm.define "kmax" do |kmax|
    kmax.vm.box = "hashicorp/bionic64"
    kmax.vm.provision "shell", privileged: false, inline: "cd /vagrant; source setup_kmax.sh"
  end
end
