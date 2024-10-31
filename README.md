# E-Commerce Website Terraform Deployment


---


## PURPOSE
A new E-Commerce company wants to deploy their application to AWS Cloud Infrastructure that is secure, available, and fault tolerant.  They also want to utilize Infrastructure as Code as well as a CICD pipeline to be able to spin up or modify infrastructure as needed whenever an update is made to the application source code.  As a growing company they are also looking to leverage data and technology for Business Intelligence to make decisions on where to focus their capital and energy on.

We're going to be using Terraform to build out our infrastructure and run our application. We can either do this semi-automatically with manual interventions or we can fully automate with Jenkins to perform our terraform deployment.

The full purpose of this deployment is for us to learn how to deploy infrastructure with Terraform and how to combine Jenkins with Terraform and understand how each tool plays a part in the CI/CD of our application.

## STEPS

### Understanding the Process
Before we dive into creating our infrastructure using Terraform, we need to understand the tech stack that we'll be using to deploy our application. This manual discovery is going to inform us on what we need in our infrastructure as well as the setup necessary on each host that we create to connect our infrastructure together for our application to be live and in production.

The purpose of performing these steps manually is to help us understand what our tech stack needs to do in order to have a functioning ecommerce app. Understanding the requirements and dependencies as well as the connection requirements is key for us automating this process in terraform.

We'll need this GitHub repo, 2x t3.micro EC2 instances, Security Groups, and software dependencies. 

1. Create one "Frontend" and one "Backend" EC2. Frontend SG - set to 22 for SSH and 3000 for REACT. Backend SG - set to 22 for SSH and 8000 for Django.
2. Clone the repo to both instances and cd into the repo.
3. On "Backend" server, install `"python3.9", "python3.9-venv", and "python3.9-dev"`.
4. Create the python3.9 virtual environment, activate, install dependencies from the  ``./backend/requirements.txt` file.
5. Modify `./backend/my_project/settings.py`. Update the "ALLOWED_HOSTS" field with the private IP of the "Backend" EC2.
6. Start the Django server by running `python manage.py runserver 0.0.0.0:8000`
7. On the "Frontend" server, install Node.js and npm.
  ```
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
  ```
8. Update the "package.json" file in `./frontend/`. Modify "proxy" field to point to "Backend" Private IP: `"proxy": "http://BACKEND_PRIVATE_IP:8000"`
9. Install frontend dependencies by ensuring you're in the `./frontend/` directory and run `npm i`
10. Set Node.js options for legacy compatibility and start the app:
  ```
  export NODE_OPTIONS=--openssl-legacy-provider
  npm start
  ```
11. Once this is complete, we should be able to go to the "Frontend" Public IP at port 3000 and see the ecommerce site with the products.
12. Delete the two EC2s as this is just a proof of concept and gaining understanding of our tech stack and what we need to make this work.

This helps us understand our tech stack better. Our Frontend is using React, Backend is Django, Database is SQLite, Infrastructure is AWS.
On top of all this we can see what the technologies we'll need to get everything up and running, working and connected together.


### INFRASTRUCTURE AS CODE AND CI/CD PIPELINE

1. Create an EC2 t3.medium called "Jenkins_Terraform" for Jenkins and Terraform. To set up my "Jenkins_Terraform" instance, I [used this script.](https://github.com/jonwang22/ecommerce_terraform_deployment/blob/main/Scripts/install_dev_setup.sh)

2. For my Terraform files, I opted to create modules for each component. I have modules for [VPC](https://github.com/jonwang22/ecommerce_terraform_deployment/tree/main/Terraform/modules/VPC), [EC2](https://github.com/jonwang22/ecommerce_terraform_deployment/tree/main/Terraform/modules/EC2), [RDS](https://github.com/jonwang22/ecommerce_terraform_deployment/tree/main/Terraform/modules/RDS), and [ALB](https://github.com/jonwang22/ecommerce_terraform_deployment/tree/main/Terraform/modules/ALB). Below is an outline of the infrastructure and resource blocks that we'll need in order for this app to work.
  ```
  ### VPC ###
  - 1x Custom VPC named "wl5vpc" in us-east-1
    - 2x Availability Zones, we're using us-east-1a and us-east-1b.
    - 2x Public Subnets and 2x Private Subnets. One of each in each AZ.
    - 1x Internet Gateway, 2x NAT Gateways and 2x Elastic IPs to assign to each NAT Gateway, one NAT in each Public Subnet. 
      (For redundancy purposes in case one AZ goes down.)
    - 3x Route Tables, 1x Public Route Table for both Public Subnets, 1x Route Table for each Private Subnet due to NAT connection for each Private Subnet.
    - 4x Route Table Associations.
      - 2x for Public Subnets to Public Route Table.
      - 2x for Private Subnets to their respective Private Route Table.
    - 1x VPC Peering Connection between Default VPC and Custom VPC.
    - Resources to call Default VPC resources and assign proper routing and associations where needed for the Default VPC to communicate with Custom VPC.
  
  ### EC2 ###
  - 1x SSH Key to use for instances so we can connect to them and troubleshoot if needed.
  - 2x Frontend Servers, 1x in each Public Subnet, in each AZ.
    These must be named "ecommerce_frontend_az1" and "ecommerce_frontend_az2" respectively.
  - 1x Frontend Security Group associated to the Frontend servers.
  - 2x Backend Servers, 1x in each Private Subnet, in each AZ.
    These must be named "ecommerce_backend_az1" and "ecommerce_backend_az2" respectively.
  - 1x Backend Security Group associated to the Backend servers.

  ### RDS ###
  - 1x RDS Postgres DB
  - 1x RDS Subnet Group, associating to the 2 Backend Private Subnets.
  - 1x RDS Security Group, determining what ports are open and which addresses can enter those ports.

  ### ALB ###
  - 1x Application Load Balancer
  - 1x Application Load Balancery Security Group, allowing port 80.
  - 1x Listener on Port 80
  - 1x Target Group for Port 3000
  - 2x Target Group Attachments, 1x for each Frontend Server at port 3000.
  ```

3. With all the resource blocks written in their respective modules, I needed to determine all my variables and outputs and created variables.tf and outputs.tf for each module. I also created a .tfvars file that holds all my sensitive secrets such as access keys and passwords. 

If needed, please refer to my terraform code to see what was done. Alot of variables were used and called in root main.tf. The biggest pain point was keeping track of all the outputs needed and dependencies for each resource block. I chose to automate this entire process so the order of creation mattered because certain information like RDS Endpoint isn't known until its created. I set "depends_on" statements for my Backend and Frontend EC2s because they required information like endpoints/private IPs. The flow of dependency went from RDS -> Backend EC2 servers -> Frontend EC2 servers. In order to automate a lot of what I needed to replicate my manual discovery of the tech stack, I used EC2's "User Data" to run scripts. You can find my [3 scripts here](https://github.com/jonwang22/ecommerce_terraform_deployment/tree/main/Terraform/scripts).

The reason why I have 3 scripts is because I have a frontend script for my frontend servers, I have 1 backend script that runs the sqlite db migration to RDS, and my second one runs the migration but connects to the RDS instance without loading anything from sqlite. There's an issue if you try to load the datadump.json to RDS you'll hit duplicate errors when RDS only allows for unique identifiers for each row in each table.

4. After testing my terraform code and manually checking the infrastructure and application works as intended, I moved on to Jenkins. 

    * Build Stage - This is where we're testing our dependencies and making sure we have everything we need for our application to work and run smoothly both Frontend and Backend.
    * Test Stage - This is conducting Django pytests on our backend application code to make sure it works properly and we have what we need for our backend migration to RDS from SQLite.
    * Init Stage - This is where we initialize Terraform for Jenkins to use.
    * Terraform Destroy - This is solely for the purposes of this deployment, in a production environment it would not be conducive to destroy your production infrastructure. This step is so we can clear out our existing infrastructure and make sure our user_data is being ran correctly on our EC2s to properly set up our Infrastructure. This is a point of optimization. How do we build a pipeline without destroy.
    * Terraform Plan - This is where our planning happens with Terraform. Terraform plan outputs an output file for us to use on our apply stage.
    * Terraform Apply - This is where the magic happens. If everything works perfectly and is configured correctly then this should turn into a one-click deploy and build out your infrastructure.

5. In order for Terraform to know where to create your resources and infrastructure, you'll need to provide Account/User Access Keys. These are very important to keep secret so we'll need to upload these as Jenkins Secrets for Jenkins to use. We'll create an Access Key Pair for our IAM User account and use these to run our Terraform.
```
1. Create a multibranch pipeline called "Workload_5" and connect your GitHub account.
2. AFTER adding your GitHub credentials (with or without saving the multibranch pipeline), navigate to the Jenkins Dashboard and click on "Manage Jenkins" on the left navagation panel.
3. Under "Security", click on "Credentials".
4. You should see the GitHub credentials you just created here.  On that same line, click on "System" and them "Global credentials (unrestricted)". (You should see more details about the GitHub credentials here (Name, Kind, Description))
5. Click on "+ Add Credentials"
6. In the "Kind" Dropdown, select "Secret Text"
7. Under "Secret", put your AWS Access Key.
8. Under "ID", put "AWS_ACCESS_KEY" (without the quotes)
9. Repeat steps 5-8 with your secret access key as "AWS_SECRET_KEY".

Jenkins is taking these credentials and storing and encrypting it for use within the Jenkinsfile as environmental variables. We then call on these credentials to use them with the "withCredentials" step. One thing to note is that your variables that you assign these credentials to are important as they have to match what is being used within Terraform, found within variables.tf. If I had to compare this, it's kind of like having a .tfvars file for Jenkins to use on Terraform. It's not a complete 1 to 1 comparison but the use case is comparable. What we would use as .tfvars file, these Jenkins credentials are what Jenkins would use when running Terraform. I also stored the DB password as well to use.

DO NOT UPLOAD OR EXPOSE YOUR KEYS ANYWHERE IN ANY FILES!
```

6. Run the Jenkins Pipeline to create and deploy the infrastructure and application! Check the load balancer DNS to make sure you can hit your application.

7. Created a "Monitoring" EC2 Instance in the Default VPC that has Prometheus and Grafana installed. Prometheus has targets on both frontend and backend servers in the Custom VPC.

## SYSTEM DESIGN DIAGRAM

![Workload5](https://github.com/user-attachments/assets/adae871c-7513-4c44-8412-91a56eed55b3)

## ISSUES/TROUBLESHOOTING

1. Creating scripts for the user_data was a big challenge. I was able to formulate the commands to completely setup all 4 servers. 

2. During Jenkins deployment, on the test stage, I found out that the settings.py needed to set sqlite as the default database so I had to keep the section for postgres database commented out and then when we move to terraform apply and move the sqlite DB to RDS, I had to uncomment out that section in settings.py as well as add the respective AZ's backend server's private IP into settings.py ALLOWED_HOSTS and the Frontend package.json "proxy" field.

3. I ran out of storage on my Jenkins server that it disabled my node worker so I had to increase storage in order for Jenkins builds to run.

4. I kept getting this issue and the main reason why is because my user data scripts on my Backend servers did not fully run. I had to dive into my scripts and correct syntax errors to get all my commands to run on my backend servers and fully set it up.
```
* Proxy error: Could not proxy request /api/products/ from 44.211.212.52:3000 to http://10.0.1.92:8000.
See https://nodejs.org/api/errors.html#errors_common_system_errors for more information (ECONNREFUSED).
```

5. I had this issue when trying to spin up my backend server. I had to modify the models.py file within backend/accounts. The Stripemodel for credit card value is set at 16 but I needed to increase it to 20. After increasing that it fixed this issue.
```
Traceback (most recent call last):

File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/backends/utils.py", line 84, in _execute
    return self.cursor.execute(sql, params)
psycopg2.errors.StringDataRightTruncation: value too long for type character varying(16)


The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/home/ubuntu/ecommerce_terraform_deployment/backend/manage.py", line 22, in <module>
    main()
  File "/home/ubuntu/ecommerce_terraform_deployment/backend/manage.py", line 18, in main
    execute_from_command_line(sys.argv)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/management/__init__.py", line 419, in execute_from_command_line
    utility.execute()
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/management/__init__.py", line 413, in execute
    self.fetch_command(subcommand).run_from_argv(self.argv)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/management/base.py", line 354, in run_from_argv
    self.execute(*args, **cmd_options)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/management/base.py", line 398, in execute
    output = self.handle(*args, **options)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/management/commands/loaddata.py", line 78, in handle
    self.loaddata(fixture_labels)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/management/commands/loaddata.py", line 123, in loaddata
    self.load_label(fixture_label)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/management/commands/loaddata.py", line 190, in load_label
    obj.save(using=self.using)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/core/serializers/base.py", line 223, in save
    models.Model.save_base(self.object, using=using, raw=True, **kwargs)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/models/base.py", line 763, in save_base
    updated = self._save_table(
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/models/base.py", line 845, in _save_table
    updated = self._do_update(base_qs, using, pk_val, values, update_fields,
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/models/base.py", line 899, in _do_update
    return filtered._update(values) > 0
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/models/query.py", line 802, in _update
    return query.get_compiler(self.db).execute_sql(CURSOR)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/models/sql/compiler.py", line 1559, in execute_sql
    cursor = super().execute_sql(result_type)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/models/sql/compiler.py", line 1175, in execute_sql
    cursor.execute(sql, params)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/backends/utils.py", line 98, in execute
    return super().execute(sql, params)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/backends/utils.py", line 66, in execute
    return self._execute_with_wrappers(sql, params, many=False, executor=self._execute)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/backends/utils.py", line 75, in _execute_with_wrappers
    return executor(sql, params, many, context)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/backends/utils.py", line 84, in _execute
    return self.cursor.execute(sql, params)
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/utils.py", line 90, in __exit__
    raise dj_exc_value.with_traceback(traceback) from exc_value
  File "/home/ubuntu/ecommerce_terraform_deployment/venv/lib/python3.9/site-packages/django/db/backends/utils.py", line 84, in _execute
    return self.cursor.execute(sql, params)
django.db.utils.DataError: Problem installing fixture '/home/ubuntu/ecommerce_terraform_deployment/backend/datadump.json': Could not load account.StripeModel(pk=140): value too long for
 type character varying(16)

Failed to load datadump.json
2024-10-29 14:39:35,624 - cc_scripts_user.py[WARNING]: Failed to run module scripts_user (scripts in /var/lib/cloud/instance/scripts)
2024-10-29 14:39:35,624 - util.py[WARNING]: Running module scripts_user (<module 'cloudinit.config.cc_scripts_user' from '/usr/lib/python3/dist-packages/cloudinit/config/cc_scripts_user
.py'>) failed
```

6. I need to figure out how to use Load Balancers and properly configure them and understand the Health checks that its performing.

## OPTIMIZATION

1. Currently my Terraform code is creating every resource individually that is causing my code to be longer than needed. I think optimizing the code would reduce the amount of code that is within my terraform files.

2. Our RDS Database currently sits within one of the private subnets. The most optimal would be to create a separate subnet for the RDS DB and to create a secondary database if budget allows to have redundancy and also help with the load in case there's more read calls from the backend and that the Primary database is not overloaded.

3. I chose to automate the whole process and deployment. That is optimal to my knowledge however one point of the automation pipeline is the Jenkinsfile. I think there should be a better pipeline to develop and deploy for steps/stages. I'm not sure how to properly refresh the state without tearing down and destroying all the infrastructure so unfortunately theres a terraform destroy stage to reset out environment to redeploy our application. The optimization is figuring out how to remove this destroy command and still be able to update the environment every deployment and build when the source code changes or new features are added.

4. Within my frontend package.json I had to add a flag that forwards my Load Balancer through. See below. I need to remove the `DANGEROUSLY_DISABLE_HOST_CHECK=true HOST=0.0.0.0 PORT=3000` portion.

```
"scripts": {
    "start": "DANGEROUSLY_DISABLE_HOST_CHECK=true HOST=0.0.0.0 PORT=3000 react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  },
```

## BUSINESS INTELLIGENCE

1. Create a diagram of the schema and relationship between the tables (keys). (Use draw.io for this question)

2. How many rows of data are there in these tables?  What is the SQL query you would use to find out how many users, products, and orders there are?

```
ecommercedb=> SELECT COUNT (*) FROM auth_user;
 count 
-------
  3003
(1 row)

ecommercedb=> SELECT COUNT (*) FROM product_product;
 count 
-------
    33
(1 row)
                              ^
ecommercedb=> SELECT COUNT (*) FROM account_billingaddress;
 count 
-------
  3004
(1 row)

ecommercedb=> SELECT COUNT (*) FROM account_stripemodel;
 count 
-------
  3002
(1 row)

ecommercedb=> SELECT COUNT (*) FROM account_ordermodel;
 count 
-------
 15005
(1 row)
```

3. Which states ordered the most products? Least products? Provide the top 5 and bottom 5 states.

```
ecommercedb=> SELECT state, count(*) AS count
FROM account_ordermodel AS aom
INNER JOIN account_billingaddress AS aba ON aom.user_id = aba.user_id
GROUP BY state
ORDER BY count DESC
LIMIT 5;
  state  | count 
---------+-------
 Alaska  |   390
 Ohio    |   386
 Montana |   381
 Alabama |   375
 Texas   |   366
(5 rows)
```

```
ecommercedb=> SELECT state, count(*) AS count
FROM account_ordermodel AS aom
INNER JOIN account_billingaddress AS aba ON aom.user_id = aba.user_id
GROUP BY state
ORDER BY count ASC
LIMIT 5;
  state   | count 
----------+-------
 ny       |     1
 unknown  |     8
 Delhi    |    16
 new york |    16
 Maine    |   224
(5 rows)
```


4. Of all of the orders placed, which product was the most sold? Please provide the top 3.

```
ecommercedb=> SELECT ordered_item, count(*) AS count
FROM account_ordermodel AS aom
INNER JOIN product_product AS p ON aom.ordered_item = p.name
GROUP BY ordered_item
ORDER BY count DESC
LIMIT 3;
                             ordered_item                              | count 
-----------------------------------------------------------------------+-------
 Logitech G305 Lightspeed Wireless Gaming Mouse (Various Colors)       |   502
 2TB Samsung 980 PRO M.2 PCIe Gen 4 x4 NVMe Internal Solid State Drive |   489
 Arcade1up Marvel vs Capcom Head-to-Head Arcade Table                  |   486
(3 rows)
```

### Database Tables and Keys

```
ecommercedb=> \dt
                    List of relations
 Schema |            Name            | Type  |   Owner    
--------+----------------------------+-------+------------
 public | account_billingaddress     | table | kurac5user
 public | account_ordermodel         | table | kurac5user
 public | account_stripemodel        | table | kurac5user
 public | auth_group                 | table | kurac5user
 public | auth_group_permissions     | table | kurac5user
 public | auth_permission            | table | kurac5user
 public | auth_user                  | table | kurac5user
 public | auth_user_groups           | table | kurac5user
 public | auth_user_user_permissions | table | kurac5user
 public | django_admin_log           | table | kurac5user
 public | django_content_type        | table | kurac5user
 public | django_migrations          | table | kurac5user
 public | django_session             | table | kurac5user
 public | product_product            | table | kurac5user
(14 rows)
```

```
ecommercedb=> \d auth_user;
                                        Table "public.auth_user"
    Column    |           Type           | Collation | Nullable |                Default                
--------------+--------------------------+-----------+----------+---------------------------------------
 id           | integer                  |           | not null | nextval('auth_user_id_seq'::regclass)
 password     | character varying(128)   |           | not null | 
 last_login   | timestamp with time zone |           |          | 
 is_superuser | boolean                  |           | not null | 
 username     | character varying(150)   |           | not null | 
 first_name   | character varying(150)   |           | not null | 
 last_name    | character varying(150)   |           | not null | 
 email        | character varying(254)   |           | not null | 
 is_staff     | boolean                  |           | not null | 
 is_active    | boolean                  |           | not null | 
 date_joined  | timestamp with time zone |           | not null | 
Indexes:
    "auth_user_pkey" PRIMARY KEY, btree (id)
    "auth_user_username_6821ab7c_like" btree (username varchar_pattern_ops)
    "auth_user_username_key" UNIQUE CONSTRAINT, btree (username)
Referenced by:
    TABLE "account_billingaddress" CONSTRAINT "account_billingaddress_user_id_274d1944_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
    TABLE "account_ordermodel" CONSTRAINT "account_ordermodel_user_id_98e8eb0c_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
    TABLE "account_stripemodel" CONSTRAINT "account_stripemodel_user_id_a3f2e757_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
    TABLE "auth_user_groups" CONSTRAINT "auth_user_groups_user_id_6a12ed8b_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
    TABLE "auth_user_user_permissions" CONSTRAINT "auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
    TABLE "django_admin_log" CONSTRAINT "django_admin_log_user_id_c564eba6_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
```

```
ecommercedb=> \d product_product
                                      Table "public.product_product"
   Column    |          Type          | Collation | Nullable |                   Default                   
-------------+------------------------+-----------+----------+---------------------------------------------
 id          | bigint                 |           | not null | nextval('product_product_id_seq'::regclass)
 name        | character varying(200) |           | not null | 
 description | text                   |           | not null | 
 price       | numeric(8,2)           |           | not null | 
 stock       | boolean                |           | not null | 
 image       | character varying(100) |           |          | 
Indexes:
    "product_product_pkey" PRIMARY KEY, btree (id)
```

```
ecommercedb=> \d account_billingaddress;
                                       Table "public.account_billingaddress"
    Column    |          Type          | Collation | Nullable |                      Default                       
--------------+------------------------+-----------+----------+----------------------------------------------------
 id           | bigint                 |           | not null | nextval('account_billingaddress_id_seq'::regclass)
 name         | character varying(200) |           | not null | 
 phone_number | character varying(10)  |           | not null | 
 pin_code     | character varying(6)   |           | not null | 
 house_no     | character varying(300) |           | not null | 
 landmark     | character varying(120) |           | not null | 
 city         | character varying(120) |           | not null | 
 state        | character varying(120) |           | not null | 
 user_id      | integer                |           |          | 
Indexes:
    "account_billingaddress_pkey" PRIMARY KEY, btree (id)
    "account_billingaddress_user_id_274d1944" btree (user_id)
Foreign-key constraints:
    "account_billingaddress_user_id_274d1944_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
```

```
ecommercedb=> \d account_stripemodel;
                                        Table "public.account_stripemodel"
     Column      |          Type          | Collation | Nullable |                     Default                     
-----------------+------------------------+-----------+----------+-------------------------------------------------
 id              | bigint                 |           | not null | nextval('account_stripemodel_id_seq'::regclass)
 email           | character varying(254) |           |          | 
 name_on_card    | character varying(200) |           |          | 
 customer_id     | character varying(200) |           |          | 
 card_number     | character varying(20)  |           |          | 
 exp_month       | character varying(2)   |           |          | 
 exp_year        | character varying(4)   |           |          | 
 card_id         | text                   |           |          | 
 address_city    | character varying(120) |           |          | 
 address_country | character varying(120) |           |          | 
 address_state   | character varying(120) |           |          | 
 address_zip     | character varying(6)   |           |          | 
 user_id         | integer                |           |          | 
Indexes:
    "account_stripemodel_pkey" PRIMARY KEY, btree (id)
    "account_stripemodel_card_number_c69e30bb_like" btree (card_number varchar_pattern_ops)
    "account_stripemodel_card_number_key" UNIQUE CONSTRAINT, btree (card_number)
    "account_stripemodel_user_id_a3f2e757" btree (user_id)
Foreign-key constraints:
    "account_stripemodel_user_id_a3f2e757_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
```

```
ecommercedb=> \d account_ordermodel;
                                        Table "public.account_ordermodel"
    Column    |           Type           | Collation | Nullable |                    Default                     
--------------+--------------------------+-----------+----------+------------------------------------------------
 id           | bigint                   |           | not null | nextval('account_ordermodel_id_seq'::regclass)
 name         | character varying(120)   |           | not null | 
 ordered_item | character varying(200)   |           |          | 
 card_number  | character varying(16)    |           |          | 
 address      | character varying(300)   |           |          | 
 paid_status  | boolean                  |           | not null | 
 paid_at      | timestamp with time zone |           |          | 
 total_price  | numeric(8,2)             |           |          | 
 is_delivered | boolean                  |           | not null | 
 delivered_at | character varying(200)   |           |          | 
 user_id      | integer                  |           |          | 
Indexes:
    "account_ordermodel_pkey" PRIMARY KEY, btree (id)
    "account_ordermodel_user_id_98e8eb0c" btree (user_id)
Foreign-key constraints:
    "account_ordermodel_user_id_98e8eb0c_fk_auth_user_id" FOREIGN KEY (user_id) REFERENCES auth_user(id) DEFERRABLE INITIALLY DEFERRED
```

### METHODS FOR ACCESSING DATABASE

For each of the following questions (besides #1), you will need to perform SQL queries on the RDS database.  There are multiple methods. here are 2:

a) From the command line, install postgresql so that you can use the psql command to connect to the db with `psql -h <RDS-endpoint> -U <username> -d <database>`. Then run SQL queries like normal from the command line. OR:

b) Use python library `psycopg2` (pip install psycopg2-binary) and connect to the RDS database with the following:

```
import psycopg2

# Database connection details
host = "<your-host>"
port = "5432"  # Default PostgreSQL port
database = "<your-database>"
user = "<your-username>"
password = "<your-password>"

# Establish the connection
conn = psycopg2.connect(
    host=host,
    database=database,
    user=user,
    password=password
)

# Create a cursor object
cur = conn.cursor()
```

you can then execute the query with:

```
cur.execute("SELECT * FROM my_table;")

# Fetch the result of the query
rows = cur.fetchall()
```

## CONCLUSION

Terraform is a really powerful DevOps tool. It was really great to work on Terraform with Jenkins to deploy this ecommerce application. Fully automating this to one click deploy is a great feeling as tough as it was to coordinate all the variables, files, and configurations. I can see how powerful this can be and how awesome it is to assist in scaling out infrastructure across regions and providing availability and reliability quickly. Terraform is also provider agnostic and you can use AWS and Azure and Google Cloud all together at once.
