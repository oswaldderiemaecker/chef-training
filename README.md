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

```
mkdir /home/vagrant/chef-repo-training/config
cp /vagrant/scripts/spork-config.yml /home/vagrant/chef-repo-training/config
cd /home/vagrant/chef-repo-training
knife spork info
knife spork environment create production
knife spork environment create staging
knife spork environment create development
```

So we have now, our Chef repository, and three environments.


Let's configure developer's 2 environments.

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

So let's code our first cookbook on developer 1 workstation.

```
vagrant ssh developer1
cd /home/vagrant/chef-repo-training
```

Create the cookbook

```
cd cookbooks/
chef generate cookbook myfirst_cookbook
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

Let's look at the chef server at: https://chefserver.vagrant.local/

Username: admin
Password: samplepass

* Looking at the Nodes we have our client-server node.
* Looking at Policy we have our myfirst_cookbook cookbook, please note the version 0.1.0
* Looking at Policy we have our Environments
* Looking at Administration we have our Organization and Users

Let's modify our cookbook.

```
vi myfirst_cookbook/recipes/default.rb
```

and add:

```
package 'vim'
```

and 

```
vi myfirst_cookbook/recipes/display_chef_environment.rb
```

and add:

```
log node.chef_environment
```

Let's check our cookbook with spork:

```
knife spork check myfirst_cookbook
```

What can we see ?

* ERROR: The version 0.1.0 exists on the server and is not frozen. Uploading will overwrite!

This is very important if the cookbook is not frozen and changes will overwrite it, this of course can lead to problems. Reasons why we will use spork.

It the run rubocop (A Ruby static code analyzer, based on the community Ruby style guide) and returns some offenses. We haven't configure rubocop to analyze our cookbook, so let's do it now:

```
cp /vagrant/scripts/.rubocop.yml /home/vagrant/chef-repo-training/
cat .rubocop.yml
```

Let's rerun our spork check.

Our rubocop pass now, Foodcritic (A lint tool for your Chef cookbooks) fails is now failing.

Let's look at the Foodcritics recommendations.

* ERROR: FC064: Ensure issues_url is set in metadata: /home/vagrant/chef-repo-training/cookbooks/myfirst_cookbook/metadata.rb:1
* ERROR: FC065: Ensure source_url is set in metadata: /home/vagrant/chef-repo-training/cookbooks/myfirst_cookbook/metadata.rb:1

Let's look at the foodcritic for more information.

http://www.foodcritic.io/ 

Let's add these in our metadata:

```
vi myfirst_cookbook/metadata.rb
```

and add:

```
issues_url 'https://github.com/<insert_org_here>/myfirst_cookbook/issues' if respond_to?(:issues_url)
source_url 'https://github.com/<insert_org_here>/myfirst_cookbook' if respond_to?(:source_url)
```

And let's spork check again.

All is fine now except our version which is not frozen which is fine for now as we don't use yet our cookbook.

Let's upload our latest changes.

```
knife cookbook upload myfirst_cookbook
```

And test our cookbook on our client server.

```
vagrant ssh client
sudo chef-client
```

Nothing happens, and its normal, we haven't given a role to our client-server, let's do that.

Let's create a role:

```
knife spork role create webserver
```

And give that role to our client-server.

```
mkdir /home/vagrant/chef-repo-training/nodes
knife spork node create client-server
``` 

and add:

```
  "run_list": [
    "role[webserver]"
  ]
```

Note: you can always use ```knife node edit client-server``` if you don't want to have your nodes in the chef repository.

Let's define our env run list:

```
knife spork role edit webserver
```

and add:

```
  "run_list": [
    "recipe[myfirst_cookbook]",
    "recipe[myfirst_cookbook::display_chef_environment]"
  ],
  "env_run_lists": {
    "production": [

    ],
    "staging": [
      "recipe[myfirst_cookbook]"
    ],
    "developmnent": [
      "recipe[myfirst_cookbook]", "recipe[myfirst_cookbook::display_chef_environment]"
    ]
  }
```

Let's connect to the client-server to run the run-list

```
vagrant ssh client
sudo chef-client
```

Now let's run on the differents environments:

```
sudo chef-client --environment production
sudo chef-client --environment staging
sudo chef-client --environment development
```

and Freez our cookbook:

```
knife cookbook upload --freeze myfirst_cookbook
```

And let's pin it to our staging environment.

```
knife spork promote staging myfirst_cookbook --remote
```

Let's commit all our changes.

```
git status
git add myfirst_cookbook/*
git add .rubocop.yml
git push origin master
```

And tag our version:

```
git tag 0.1.0
git push origin 0.1.0
```

Let's assume, developer 2 now has to modify the cookbook. Let's connect to developer 2 workstation.

```
/home/vagrant/chef-repo-training
git pull origin master
```

Let's modify the default recipes and add:

```
package 'emacs'
```

and try to upload our cookbook:

```
knife cookbook upload myfirst_cookbook
```

We got an error: ERROR: Version 0.1.0 of cookbook myfirst_cookbook is frozen. Use --force to override.

This is where spork comes handy, let's use it:

```
knife spork bump myfirst_cookbook minor
cat myfirst_cookbook/metadata.rb
```

Note: **Present Semantic Versioning**

Let's run spork check:

```
knife spork check myfirst_cookbook
```

Let's upload the cookbook:

```
knife cookbook upload myfirst_cookbook
```

Let's pin it to our development environment.

```
knife spork promote development myfirst_cookbook --remote
```

Now let's run on the client server:

```
sudo chef-client --environment production
sudo chef-client --environment staging
sudo chef-client --environment development
```

Let's commit all our changes.

```
git status
git add myfirst_cookbook/*
git add .rubocop.yml
git commit -m "Adding emacs"
git push origin master
```

And tag our version:

```
git tag 0.2.0
git push origin 0.2.0
```
