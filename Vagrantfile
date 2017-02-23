# -*- mode: ruby -*-
# vi: set ft=ruby :

# default box when no VAGRANT_BOX / VAGRANT_BOX_URL environment is set
BOX_NAME = "ubuntu/trusty64"
BOX_URL  = "https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box"

CHEF_CLIENT_INSTALL = <<-EOF
#!/bin/sh
echo "Chef Installation"
test -d /opt/chef || {
  echo "Installing chef-client via omnibus"
  curl -L -s https://www.opscode.com/chef/install.sh | sudo bash
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
    sudo chef-server-ctl org-user-add myorganization developer1 -a admin
    sudo chef-server-ctl org-user-add myorganization developer2 -a admin
    sudo chef-server-ctl org-user-add myorganization client -a clients
  
  echo "Chef Server Done."
}
EOF

CHEF_WORKSTATION_CHEF_REPO_INSTALL = <<-EOF
#!/bin/sh
echo "Installing git"
sudo apt-get update
sudo apt-get -y install git docker.io
echo "Generating chef repo with chef dk"
chef generate repo chef-repo-training
echo "Configuring git_ssh.sh script"
echo "export GIT_SSH=/home/vagrant/.chef/scripts/git_ssh.sh" >> ~/.bash_profile 
EOF

CHEF_WORKSTATION_INSTALL = <<-EOF
#!/bin/sh
echo "Installing git"
sudo apt-get update
sudo apt-get -y install git docker.io
echo "Configuring git_ssh.sh script"
echo "export GIT_SSH=/home/vagrant/.chef/scripts/git_ssh.sh" >> ~/.bash_profile 
EOF

CHEF_CLIENT_CONFIG = <<-EOF
echo "Bootstraping the client server"
knife bootstrap client.vagrant.local -N client-server -x vagrant -P vagrant --sudo --use-sudo-password --node-ssl-verify-mode none --yes 
EOF

def knife_config(client)
"
#!/bin/sh
echo 'Knife configuration'
cat <<EOK > /home/vagrant/.chef/knife.rb
cwd                     = File.dirname(__FILE__)
log_level               :info   # valid values - :debug :info :warn :error :fatal
log_location            STDOUT
node_name               ENV.fetch('KNIFE_NODE_NAME', '#{ client }')
client_key              ENV.fetch('KNIFE_CLIENT_KEY', File.join(cwd,'#{ client }.pem'))
chef_server_url         ENV.fetch('KNIFE_CHEF_SERVER_URL', 'https://chefserver.vagrant.local/organizations/myorganization')
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

end
