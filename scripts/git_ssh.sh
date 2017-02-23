#!/bin/sh
exec /usr/bin/ssh -o StrictHostKeyChecking=no -i /home/vagrant/.ssh/id_rsa "$@"
