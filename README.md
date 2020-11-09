## Prerequisite:

- Install [Terraform](https://www.terraform.io/downloads.html)

- Install [Git](https://git-scm.com/downloads)

- Install any remote SSH client like [Putty and PuTTYgen](https://www.putty.org/)

- Create Key Pair. It will be used to connect AWS instances

In PuTTYgen -> Generate -> Save public key (in local machine)-> Save private key (in local machine). 

Keep these keys in a local machine, we will be using this later.


## Steps:

1. Clone this repo and update terraform.tfvars file inside Terraform folder

Example:
```
key_name="asif-alation"
public_key_path="C:/Asif/AWS/asif-alation.pub"
aws_access_key="XXXXXXXXXXXXXXXXXX"
aws_secret_key="XXXXXXXXXXXXXXXXXXXXXXXXXXXXX" 
```

2. Run Terraform templates. This will provision AWS instances and application load balancer.

```
terraform init
terraform plan
terraform apply
```

Note the output variables, address and aws_instance_dns. We will use this later.


3. Install Ansible

Usually configuration management tool like ansible is installed in the separate instance. However for the assignment, you can use one of the two servers provided. 

Connect to the server using private key created in the prerequisite step. You can use any one of two aws_instance_dns we noted in the step 2. Username (default) is ubuntu.

```
sudo apt-get -y update
sudo apt-get -y install software-properties-common
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt-get -y install ansible
```

4. In the server, append the below in /etc/ansible/hosts file. These two are output which we noted in the step 2.

```
[servers]
ec2-3-138-218-15.us-east-2.compute.amazonaws.com
ec2-3-131-8-51.us-east-2.compute.amazonaws.com
```

3. Copy the private key (e.g. asif-alation.ppk) noted in the prerequisite step. Paste it in the in ~/.ssh file of aws instance. Convert it to .pem format using the below command. 

```
sudo apt-get install putty-tools
puttygen ~/.ssh/asif-alation.ppk -O private-openssh -o ~/.ssh/asif-alation.pem
```
Note: Check file permissions if you face any issue.
Reference: https://askubuntu.com/questions/818929/login-ssh-with-ppk-file-on-ubuntu-terminal


4. Run the command below to test the connection to second aws instance.

```
ssh -i ~/.ssh/asif-alation.pem ubuntu@<DNS name of second server noted in the step 2>. 

E.g. sudo ssh -i ~/.ssh/asif-alation.pem ubuntu@ec2-3-131-8-51.us-east-2.compute.amazonaws.com
 ```
 
Note: If you face permissions on the target directory issue, run ``` sudo chown -R ubuntu:ubuntu .ansible/ ```


5. Inside /etc/ansible/ansible.cfg, under [defaults] update private key path

E.g. private_key_file = /home/ubuntu/.ssh/asif-alation.pem


6. CD in to home directory and run ansible playbook

``` sudo ansible-playbook ansible/nginx.yml -u ubuntu ```

7. In /etc/nginx/sites-enabled/default file, add "ssi on" on both aws instances and run ```sudo service nginx restart```

Example:
```
location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                ssi on;
                try_files $uri $uri/ =404;
        }
```


8. Infrastructure testing

8.1 Create new folder mkdir ~/.aws and then create ~/.aws/config and ~/.aws/credentials files

In ~/.aws/credentials, add the following

[default]
aws_access_key_id=XXXXXXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX

In ~/.aws/config add below
[default]
region=us-east-2

Reference Link: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

8.2. Install inpec 

curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec

Reference Link: https://github.com/inspec/inspec#installation

8.3 Run inspec:

``` inspec init profile --platform aws my-profile ```

Replace example.rb file content with the cloned file

8.4 Run inspec

``` inspec exec ~/my-profile/controls/example.rb -t aws:// ```

