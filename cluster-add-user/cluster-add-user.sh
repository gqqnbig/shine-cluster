#!/usr/bin/zsh -e

if [[ $EUID -eq 0 ]]; then
	echo "$0 is designed to run without prefixing sudo" >&2
	exit 1
fi

username=$argv[-1]
[[ -z $email ]] && echo '--email is not specified.' >&2 && exit 1
[[ -z $publicKey ]] && echo '--public-key is not specified.' >&2 && exit 1



if (( $argv[(Ie)--zsh] )); then
	s='--shell /usr/bin/zsh'
else
	s=''
fi

sudo adduser --conf adduser.conf --disabled-password $=s  $username

uid=$(id -u $username)
gid=$(id -g $username)

sudo btrfs qgroup create 1/$uid /home

sudo mv /home/$username /home/$username-tmp

sudo btrfs subvolume create -i 1/$uid /home/$username
sudo btrfs subvolume create -i 1/$uid /home/shared/$username
sudo chown $username: /home/$username
sudo chown $username: /home/shared/$username

sudo mv /home/$username-tmp/*(D) /home/$username
sudo rm -rf /home/$username-tmp

sudo ln -s /home/shared/$username /home/$username/shared

sudo usermod -aG conda-cache $username

sudo -u $username cp ../slurm-examples/* /home/$username/shared/



gecos=$(getent passwd $username | cut -d ':' -f 5)

remoteFile=~/shared/remote-add-user
cat <<HERE > $remoteFile
#!/bin/bash -e
sudo addgroup --gid $gid $username
# It's not documented clearly, but --gid requires the existence of GID.
sudo adduser --gecos "$gecos" --disabled-login --uid $uid --gid $gid $username
sudo usermod -aG conda-cache $username

sudo ln -s /home/shared/$username /home/$username/shared
HERE

chmod +x $remoteFile

computeNodes=(
eureka
tatooine
)

for server in "$computeNodes[@]"
do
	echo $server
	if ! ssh -o StrictHostKeyChecking=no $server $remoteFile; then
		echo "Failed to execute remote command, please run ~/shared/remote-add-user on $server."
	fi
done

read -p "In the next screen, you will paste public key. Press enter to continue."
sudo mkdir -p /home/$username/.ssh
sudoedit /home/$username/.ssh/authorized_keys
sudo chmod 700 /home/$username/.ssh
sudo chmod 600 /home/$username/.ssh/authorized_keys
sudo chown -R $username:$username /home/$username/.ssh
