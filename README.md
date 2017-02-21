# Chef Advanced Training

## The Environments

The aim of this training is to show how to work in Teams with Chef in multiple environments.

This training use four vagrants, one chef servers, two developers workstation and one client that we will use to test our cookbooks.

We use [Sporks](https://github.com/jonlives/knife-spork) to set a workflow to work on our cookbooks.

### Starting and configuring the environments

```
vagrant up
```

Once all vagrants has started.

The Vagrant [CHEF_SERVER_INSTALL](https://github.com/oswaldderiemaecker/chef-training/blob/master/Vagrantfile#L29) install chef server, create an organization **myorganization**, one admin and two developers user account with admin rights, the one client user.

#### Connecting to the developers vagrant to set your git chef repository

Create a github repository called chef-repo-training on your organization or user account, like:
```
https://github.com/oswaldderiemaecker/chef-repo-training
``` 

##### Copy your github ssh public key

```
scp id_dsa vagrant@developer1.vagrant.local:/home/vagrant/.ssh/id_rsa
```

#### Connect to the developer1 workstation:

```
vagrant ssh developer1
```

The Vagrant [CHEF_WORKSTATION_INSTALL](https://github.com/oswaldderiemaecker/chef-training/blob/master/Vagrantfile#L57) has generated the base chef repository available in /home/vagrant/chef-repo-training.

```
cd /home/vagrant/chef-repo-training
git init
git config --global user.email "developer1@myorganization-e4r5f4.com"
git config --global user.name "Developer 1"
git add README.md
git commit -m "Initial myorganization chef repot"
git remote add origin git@github.com:oswaldderiemaecker/chef-repo-training.git
git push -u origin master
```

#### Configuring our environments Using Spork

cd /home/vagrant/chef-repo-training
knife spork info
knife spork environment create production
knife spork environment create staging
knife spork environment create development

#### Connecting to the developer2 workstation

```
vagrant ssh developer2
```

The Vagrant [CHEF_DK_INSTALL](https://github.com/oswaldderiemaecker/chef-training/blob/master/Vagrantfile#L17) install the Chef Development Kit.
The Vagrant [CHEF_WORKSTATION_INSTALL](https://github.com/oswaldderiemaecker/chef-training/blob/master/Vagrantfile#L57) has generated the base chef repository available in /home/vagrant/chef-repo-training.

```
cd /home/vagrant
git clone git@github.com:oswaldderiemaecker/chef-repo-training.git
git config --global user.email "developer2@myorganization-e4r5f4.com"
git config --global user.name "Developer 2"
```

#### Conncecting to the client server

```
vagrant ssh client
```

The Vagrant use the [CHEF_CLIENT_INSTALL](https://github.com/oswaldderiemaecker/chef-training/blob/master/Vagrantfile#L8) and [CHEF_CLIENT_CONFIG](https://github.com/oswaldderiemaecker/chef-training/blob/master/Vagrantfile#L68) to install and configure the client-server. 

## Coding our first cookbook on the developer 1 workstation

```
vagrant ssh developer1
cd /home/vagrant/chef-repo-training
```

Create the cookbook

```
knife cookbook create myfirst_cookbook
```

Look at the cookbook version

```
cd cookbooks/myfirst_cookbook
cat metadata.rb
```

The version is '0.1.0', lets now upload our cookbook.

```
knife cookbook upload myfirst_cookbook
```

Adding the cookbook in the client-server run-list.

```
knife node run_list add client-server myfirst_cookbook
```

Checking the node run-list.

```
knife node show client-server
```

### Connecting to the client-server to run the run-list

```
vagrant ssh client
sudo chef-client
```


