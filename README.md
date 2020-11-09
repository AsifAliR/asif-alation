## Prerequisite:

- Install [Terraform](https://www.terraform.io/downloads.html)

- Install [Git](https://git-scm.com/downloads)

- Install any remote SSH client like [Putty and PuTTYgen](https://www.putty.org/)

- Create Key Pair. It will be used to connect AWS instances

In PuTTYgen -> Generate -> Save public key (in local machine)-> Save private key (in local machine). 

Keep these keys in a local machine, we will use this later.


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

Usually configuration management tool like ansible is installed in the separate instance. However for this assignment, you can also use one of the two servers provided or can use local machine. 

Connect to any one aws instance using private key created in the prerequisite step. You can use any one of two aws_instance_dns we noted in the step 2 or use local machine. Username (default) of aws instance is ubuntu. 

Install ansible using commands below

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

5. Copy the private key (e.g. asif-alation.ppk) noted in the prerequisite step. Paste it in the in ~/.ssh file of aws instance/local machine. Convert it to .pem format using the below command. 

```
sudo apt-get install putty-tools
puttygen ~/.ssh/asif-alation.ppk -O private-openssh -o ~/.ssh/asif-alation.pem
```
Note: Check file permissions if you face any issue.

Reference: https://askubuntu.com/questions/818929/login-ssh-with-ppk-file-on-ubuntu-terminal


6. Run the command below to test the connection of aws instances.

```
ssh -i ~/.ssh/asif-alation.pem ubuntu@<DNS name of server noted in the step 2>. 

E.g. 
sudo ssh -i ~/.ssh/asif-alation.pem ubuntu@ec2-3-131-8-51.us-east-2.compute.amazonaws.com
sudo ssh -i ~/.ssh/asif-alation.pem ubuntu@ec2-3-138-218-15.us-east-2.compute.amazonaws.com
 ```
 
Note: If you face permissions on the target directory issue, run ``` sudo chown -R ubuntu:ubuntu .ansible/ ```


7. Inside /etc/ansible/ansible.cfg, under [defaults] update private key path

```E.g. private_key_file = /home/ubuntu/.ssh/asif-alation.pem ```


8. CD in to home directory and run ansible playbook

``` sudo ansible-playbook ansible/nginx.yml -u ubuntu ```

9. In /etc/nginx/sites-enabled/default file, add "ssi on" on both aws instances and run ```sudo service nginx restart```

Example:
```
location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
                ssi on;
                try_files $uri $uri/ =404;
        }
```


10. Infrastructure testing

10.1 Create new folder mkdir ~/.aws and then create ~/.aws/config and ~/.aws/credentials files in the any one of the aws instance or local machine

In ~/.aws/credentials, add the following

[default]
aws_access_key_id=XXXXXXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX

In ~/.aws/config add below
[default]
region=us-east-2

Reference Link: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html

10.2. Install inpec 

``` curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec ```

Reference Link: https://github.com/inspec/inspec#installation

10.3 Run inspec:

``` inspec init profile --platform aws my-profile ```

Replace example.rb file content with the cloned file

10.4 Run inspec

``` inspec exec ~/my-profile/controls/example.rb -t aws:// ```

11. Curl <address output variable noted in the step2> or paste this address in the browser

Run curl multiple times or press Ctrl + F5. You can see different web server identifier. This proves web server is load balanced.

Now delete one of the two web servers, and run curl or press Ctrl + F5. You can see static web server ID. This proves load balancer fail over to healthy instance.

![Web server](/Load_balanced_web_server.png)

## Essential Result:
 - Web servers return “Hello World" along with web server identifier
 - Removal of either one of web servers will automatically fail over to the other server
 - Load balancer configured to use round robin algorithm by default. Sticky sessions can also be configured.
 - What I liked about the solution: 
   - Fault tolerance solution
   - Immutable infrastructure achieved by using terraform
   - Configuration management and automation using ansible  
 - What can be improved in the solution:
   - Solution does not consider security best practices, web server should be hosted in the private subnet, and should allow connection from load balancer hosted in the public subnet
   - Web servers should span across availability zone to achieve high availability
   - Configuration management tool like ansible can also be used for deployment. I suppose it is omitted with purpose, to keep the solution simple

