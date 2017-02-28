# -*- mode: ruby -*-
# vi: set ft=ruby :

# default box when no VAGRANT_BOX / VAGRANT_BOX_URL environment is set
BOX_NAME = "ubuntu/ubuntu1604"
BOX_URL  = "https://atlas.hashicorp.com/geerlingguy/boxes/ubuntu1604/versions/1.0.9/providers/virtualbox.box"

CHEF_CLIENT_INSTALL = <<-EOF
#!/bin/sh
echo "Chef Installation"
test -d /opt/chef || {
  echo "Installing chef-client via omnibus"
  curl -L -s https://www.opscode.com/chef/install.sh | sudo bash
}
EOF

CHEF_AUTOMATE_INSTALL = <<-EOF
#!/bin/sh
echo "Chef Delivery Installation"
test -d /opt/delivery || {
  echo "Installing chef-delivery"
  curl -o /tmp/delivery_0.6.136-1_amd64.deb -s https://packages.chef.io/files/stable/delivery/0.6.136/ubuntu/16.04/delivery_0.6.136-1_amd64.deb 
  sudo dpkg -i /tmp/delivery_0.6.136-1_amd64.deb
  # Run preflight check
  sudo automate-ctl preflight-check
  # Run setup
  sudo automate-ctl setup --license /vagrant/automate.license --key /vagrant/.chef_delivery/delivery.pem --server-url https://chefserver/organizations/myorganization --fqdn $(hostname) --enterprise myorganization --configure --no-build-node
  # Wait for all services to come online
  until (curl --insecure -D - https://delivery/api/_status) | grep "200 OK"; do sleep 15s; done
  while (curl --insecure https://delivery/api/_status) | grep "fail"; do sleep 15s; done
  # Create enterprise
  sudo automate-ctl create-enterprise default --ssh-pub-key-file=/vagrant/.chef_delivery/delivery.pem > /vagrant/.chef_delivery/admin_pass.local.txt
  # Create an initial user
  sudo automate-ctl create-user default developer1 --password samplepass --roles "admin"
  sudo automate-ctl create-user default developer2 --password samplepass --roles "admin"
  sudo automate-ctl install-runner runner vagrant --password vagrant --enterprise default
}
EOF

CHEF_DK_INSTALL = <<-EOF
#!/bin/sh
test -f /opt/chefdk/bin/kitchen || {
  echo "Installing chef-dk"
  cd /tmp
  curl -L -s 'https://packages.chef.io/files/stable/chefdk/1.1.16/ubuntu/14.04/chefdk_1.1.16-1_amd64.deb' > chefdk.deb 
  sudo dpkg -i chefdk.deb
  chef verify
  echo 'eval "$(chef shell-init bash)"' >> ~/.bash_profile
  echo 'export EDITOR=/usr/bin/vim' >> ~/.bash_profile
}
EOF

CHEF_SERVER_INSTALL = <<-EOF
#!/bin/sh
test -d /opt/chef-server || {
  test -f /usr/bin/chef-server-ctl || {
  echo "Installing chef-server"
    cd /tmp
    curl -L -s 'http://www.opscode.com/chef/download-server?p=ubuntu&pv=12.11&m=x86_64' > chef-server.deb
    sudo dpkg -i chef-server.deb
    echo "Installing Management Console"
    sudo chef-server-ctl install chef-manage
    sudo chef-server-ctl reconfigure
    sudo opscode-manage-ctl reconfigure --accept-license
    }
    echo "Configure Chef Admin User and Organization"
    cd /home/vagrant
    sudo chef-server-ctl org-create myorganization "MyOrganization, Inc." --association_user admin -f .chef/myorganization-validator.pem
    sudo rm -f .chef/admin.pem && sudo chef-server-ctl user-create admin admin admin admin@example.com samplepass -f .chef/admin.pem --orgname myorganization 
    sudo rm -f .chef/developer1/developer1.pem && sudo chef-server-ctl user-create developer1 developer1 developer1 developer1@example.com samplepass -f .chef/developer1/developer1.pem
    sudo rm -f .chef/developer1/developer2.pem && sudo chef-server-ctl user-create developer2 developer2 developer2 developer2@example.com samplepass -f .chef/developer2/developer2.pem
    sudo rm -f .chef/client/client.pem && sudo chef-server-ctl user-create client client client client@example.com samplepass -f .chef/client/client.pem
    sudo rm -f .chef/delivery/delivery.pem && sudo chef-server-ctl user-create delivery delivery delivery delivery@example.com samplepass -f .chef/delivery/delivery.pem
    sudo chef-server-ctl org-user-add myorganization developer1 -a admin
    sudo chef-server-ctl org-user-add myorganization developer2 -a admin
    sudo chef-server-ctl org-user-add myorganization client -a clients
    sudo chef-server-ctl org-user-add myorganization delivery -a delivery
    # Configuring Delivery
    sudo echo 'data_collector["root_url"] = "https://delivery/data-collector/v0/"' > /etc/opscode/chef-server.rb
    sudo echo 'data_collector["token"] = "93a49a4f2482c64126f7b6015e6b0f30284287ee4054ff8807fb63d9cbd1c506"' >> /etc/opscode/chef-server.rb
    sudo chef-server-ctl reconfigure

  echo "Chef Server Done."
}
EOF

CHEF_WORKSTATION_CHEF_REPO_INSTALL = <<-EOF
#!/bin/sh
test -d /home/vagrant/chef-repo-training || {
  echo "Installing git"
  sudo apt-get update
  sudo apt-get -y install git docker.io
  echo "Adding vagrant user to docker group"
  sudo gpasswd -a ${USER} docker
  sudo rm /etc/apparmor.d/docker
  sudo /etc/init.d/apparmor force-reload
  echo "Generating chef repo with chef dk"
  chef generate repo chef-repo-training
  echo "Configuring git_ssh.sh script"
  echo "export GIT_SSH=/home/vagrant/.chef/scripts/git_ssh.sh" >> ~/.bash_profile 
  echo 'export EDITOR=/usr/bin/vim' >> ~/.bash_profile
}
EOF

CHEF_WORKSTATION_INSTALL = <<-EOF
#!/bin/sh
test -d /home/vagrant/chef-repo-training || {
  echo "Installing git"
  sudo apt-get update
  sudo apt-get -y install git docker.io
  echo "Adding vagrant user to docker group"
  sudo gpasswd -a ${USER} docker
  sudo rm /etc/apparmor.d/docker
  sudo /etc/init.d/apparmor force-reload
  echo "Configuring git_ssh.sh script"
  echo "export GIT_SSH=/home/vagrant/.chef/scripts/git_ssh.sh" >> ~/.bash_profile 
  echo 'export EDITOR=/usr/bin/vim' >> ~/.bash_profile
  ssh-keygen -N "" -t ssh-rsa -f ~/.ssh/id_rsa_developer1
  ssh-keygen -N "" -t ssh-rsa -f ~/.ssh/id_rsa_developer2
}
EOF

CHEF_CLIENT_CONFIG = <<-EOF
echo "Bootstraping the client server"
knife bootstrap client.vagrant.local -N client-server -x vagrant -P vagrant --sudo --use-sudo-password --node-ssl-verify-mode none --yes 
EOF

CHEF_RUNNER_CONFIG = <<-EOF
echo "Bootstraping the runner"
knife bootstrap runner.vagrant.local -N runner -x vagrant -P vagrant --sudo --use-sudo-password --node-ssl-verify-mode none --yes 
EOF

# Generate Knife Config file
def knife_config(node_name)
"
#!/bin/sh
echo 'Knife configuration'
cat <<EOK > /home/vagrant/.chef/knife.rb
cwd                     = File.dirname(__FILE__)
log_level               :info   # valid values - :debug :info :warn :error :fatal
log_location            STDOUT
node_name               ENV.fetch('KNIFE_NODE_NAME', '#{ node_name }')
client_key              ENV.fetch('KNIFE_CLIENT_KEY', File.join(cwd,'#{ node_name }.pem'))
chef_server_url         ENV.fetch('KNIFE_CHEF_SERVER_URL', 'https://chefserver/organizations/myorganization')
validation_client_name  ENV.fetch('KNIFE_CHEF_VALIDATION_CLIENT_NAME', 'chef-validator')
validation_key          ENV.fetch('KNIFE_CHEF_VALIDATION_KEY', File.join(cwd,'myorganization-validator.pem'))
syntax_check_cache_path File.join(cwd,'syntax_check_cache')
cookbook_path           File.join(cwd,'..','chef-repo-training/cookbooks')
data_bag_path           File.join(cwd,'..','chef-repo-training/data_bags')
role_path               File.join(cwd,'..','chef-repo-training/roles')
ssl_verify_mode         :verify_none
EOK
"
end

$logger = Log4r::Logger.new('vagrantfile')
def read_ip_address(machine)
  command = "LANG=en ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1 }'"
  result  = ""

  $logger.info "Processing #{ machine.name } ... "

  begin
    # sudo is needed for ifconfig
    machine.communicate.sudo(command) do |type, data|
      result << data if type == :stdout
    end
    $logger.info "Processing #{ machine.name } ... success"
  rescue
    result = "# NOT-UP"
    $logger.info "Processing #{ machine.name } ... not running"
  end

  # the second inet is more accurate
  result.chomp.split("\n").last
end

Vagrant.configure("2") do |config|

  config.vm.box = ENV.fetch("VAGRANT_BOX", BOX_NAME)
  config.vm.box_url = ENV.fetch("VAGRANT_BOX_URL", BOX_URL)

  config.nfs.map_uid = 1000 
  config.nfs.map_gid = 1000 

  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.include_offline = true

  # Custom IP Resolver
  config.hostmanager.ip_resolver = proc do |machine|
    read_ip_address(machine)
  end

  # Chef Server
  config.vm.define :chef_server, primary: true do |chef_server|
    chef_server.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 2048]
    end

    # Change to linux__nfs_options/bsd__nfs_options based on your OS
    chef_server.vm.synced_folder "./.chef", 
	                         "/home/vagrant/.chef", 
				 type: "nfs", 
				 :bsd__nfs_options => ['rw','no_subtree_check','all_squash','async']

    chef_server.vm.network "private_network", type: "dhcp"
    chef_server.vm.network :forwarded_port,
  	      guest: 22,
  	      host: 2122,
  	      id: "ssh",
              auto_correct: true

    chef_server.vm.host_name = "chefserver"
    chef_server.hostmanager.aliases = %w(chefserver.vagrant.local chefserver)
    chef_server.vm.provision :shell, :inline => CHEF_SERVER_INSTALL
  end

  # Developer 1 Workstation
  config.vm.define :developer1, primary: true do |developer1|
    config.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 256]
    end
    # Copying key from Server to Developer Workstation
    config.trigger.before :up do
      info "Copying Developer 1 Key"
      run  "cp -f .chef/developer1/developer1.pem .chef_developer1/developer1.pem" 
      run  "cp -Rpf ./scripts .chef_developer1"
    end

    developer1.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 1024]
    end

    developer1.vm.synced_folder "./.chef_developer1", 
	                        "/home/vagrant/.chef", 
				type: "nfs",
				:bsd__nfs_options => ['rw','no_subtree_check','all_squash','async']

    developer1.vm.network "private_network", type: "dhcp"
    developer1.vm.network :forwarded_port,
  	      guest: 22,
  	      host: 2322,
  	      id: "ssh",
              auto_correct: true
    developer1.vm.host_name = "developer1.vagrant.local"
    developer1.hostmanager.aliases = %w(developer1.vagrant.local developer1)
    developer1.vm.provision :shell, :inline => CHEF_DK_INSTALL, privileged: false
    developer1.vm.provision :shell, :inline => CHEF_WORKSTATION_CHEF_REPO_INSTALL, privileged: false
    developer1.vm.provision :shell, :inline => knife_config('developer1')
  end

  # Developer 2 Workstation
  config.vm.define :developer2, primary: true do |developer2|
    config.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 256]
    end
    # Copying key from Server to Developer Workstation
    config.trigger.before :up do
      info "Copying Developer 2 Key"
      run  "cp -f .chef/developer2/developer2.pem .chef_developer2/developer2.pem" 
      run  "cp -Rpf ./scripts .chef_developer2"
    end

    developer2.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 1024]
    end

    developer2.vm.synced_folder "./.chef_developer2",
	                        "/home/vagrant/.chef", 
				type: "nfs",
				:bsd__nfs_options => ['rw','no_subtree_check','all_squash','async']

    developer2.vm.network "private_network", type: "dhcp"
    developer2.vm.network :forwarded_port,
  	      guest: 22,
  	      host: 2322,
  	      id: "ssh",
              auto_correct: true
    developer2.vm.host_name = "developer2.vagrant.local"
    developer2.hostmanager.aliases = %w(developer2.vagrant.local developer2)
    developer2.vm.provision :shell, :inline => CHEF_DK_INSTALL
    developer2.vm.provision :shell, :inline => CHEF_WORKSTATION_INSTALL, privileged: false
    developer2.vm.provision :shell, :inline => knife_config('developer2')
  end

  # Chef Client
  config.vm.define :client, primary: true do |client|
    config.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 256]
    end
    # Copying key from Server to Client
    config.trigger.before :up do
      info "Copying Client Key"
      run  "cp .chef/client/client.pem ./.chef_client/client.pem"
    end
    client.vm.synced_folder "./.chef_client", 
	                    "/home/vagrant/.chef", 
			    type: "nfs",
			    :bsd__nfs_options => ['rw','no_subtree_check','all_squash','async']

    client.vm.network "private_network", type: "dhcp"
    client.vm.network :forwarded_port,
  	      guest: 22,
  	      host: 2322,
  	      id: "ssh",
              auto_correct: true

    client.vm.host_name = "client.vagrant.local"
    client.hostmanager.aliases = %w(client.vagrant.local client)
    client.vm.provision :shell, :inline => CHEF_CLIENT_INSTALL
    client.vm.provision :shell, :inline => knife_config('client'), privileged: false
    client.vm.provision :shell, :inline => CHEF_CLIENT_CONFIG
  end

  # Chef Runner
  config.vm.define :runner, primary: true do |runner|
    config.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 256]
    end
    # Copying key from Server to Client
    config.trigger.before :up do
      info "Copying Client Key"
      run  "cp .chef/delivery/delivery.pem ./.chef_runner/runner.pem"
    end
    runner.vm.synced_folder "./.chef_runner", 
	                    "/home/vagrant/.chef", 
			    type: "nfs",
			    :bsd__nfs_options => ['rw','no_subtree_check','all_squash','async']

    runner.vm.network "private_network", type: "dhcp"
    runner.vm.network :forwarded_port,
  	      guest: 22,
  	      host: 2322,
  	      id: "ssh",
              auto_correct: true

    runner.vm.host_name = "runner.vagrant.local"
    runner.hostmanager.aliases = %w(runner.vagrant.local runner)
    runner.vm.provision :shell, :inline => CHEF_CLIENT_INSTALL
    runner.vm.provision :shell, :inline => knife_config('runner'), privileged: false
    runner.vm.provision :shell, :inline => CHEF_RUNNER_CONFIG
  end

  # Chef Automate
  config.vm.define :delivery, primary: true do |delivery|
    config.vm.provider :virtualbox do |v, override|
      v.customize ["modifyvm", :id, "--memory", 1024]
    end
    # Copying key from Server to Client
    config.trigger.before :up do
      info "Copying Delivery Key"
      run  "cp .chef/delivery/delivery.pem ./.chef_delivery/delivery.pem"
    end
    delivery.vm.synced_folder "./.chef_delivery", 
	                    "/home/vagrant/.chef", 
			    type: "nfs",
			    :bsd__nfs_options => ['rw','no_subtree_check','all_squash','async']

    delivery.vm.network "private_network", type: "dhcp"
    delivery.vm.network :forwarded_port,
  	      guest: 22,
  	      host: 2322,
  	      id: "ssh",
              auto_correct: true

    delivery.vm.host_name = "delivery.vagrant.local"
    delivery.hostmanager.aliases = %w(delivery.vagrant.local delivery)
    delivery.vm.provision :shell, :inline => CHEF_AUTOMATE_INSTALL
    delivery.vm.provision :shell, :inline => knife_config('delivery'), privileged: false
  end

end
