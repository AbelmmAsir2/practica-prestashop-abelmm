Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.define "prestashop" do |ps|
    ps.vm.hostname = "AbelMartinPrestaShop"
    ps.vm.network "forwarded_port", guest: 80, host: 18080, host_ip: "127.0.0.1"
    ps.vm.network "forwarded_port", guest: 443, host: 18443, host_ip: "127.0.0.1"
    ps.vm.provider "virtualbox" do |vb|
      vb.name = "AbelPrestaShop"
      vb.memory = 3072
      vb.cpus = 2
    end
    ps.vm.provision "shell", inline: "bash /vagrant/scripts/install_lamp.sh"
    ps.vm.provision "shell", inline: "bash /vagrant/scripts/setup_letsencrypt_https.sh"
    ps.vm.provision "shell", inline: "bash /vagrant/scripts/deploy_prestashop.sh"
  end
end
