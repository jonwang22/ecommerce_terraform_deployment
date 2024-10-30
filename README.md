# E-Commerce Website Terraform Deployment


---


## Infrastructure as Code

Welcome to Deployment Workload 5! In Workload 4 we built out our infrastructure to increase security and distrubute the resources.  Those are only some aspects of creating a "good system" though.  Let's keep optimizing.

Be sure to document each step in the process and explain WHY each step is important to the pipeline.

A new E-Commerce company wants to deploy their application to AWS Cloud Infrastructure that is secure, available, and fault tolerant.  They also want to utilize Infrastructure as Code as well as a CICD pipeline to be able to spin up or modify infrastructure as needed whenever an update is made to the application source code.  As a growing company they are also looking to leverage data and technology for Business Intelligence to make decisions on where to focus their capital and energy on.

## Instructions

### Understanding the process
Before automating the deployment of any application, you should first deploy it "locally" (and manually) to know what the process to set it up is. The following steps 2-11 will guide you to do just that before automating a CICD pipeline.

IMPORTANT: THE 2 EC2's CREATED FOR THESE FIRST 11 STEPS MUST BE TERMINATED AFTERWARD SO THAT THE ONLY RESOURCES THAT ARE IN THE ACCOUNT ARE FOR JENKINS/TERRAFORM, MONITORING, AND THE INFRASTRUCTURE THAT TERRAFORM CREATES!

1. Clone this repo to your GitHub account. IMPORTANT: Make sure that the repository name is "ecommerce_terraform_deployment"

2. Create 2x t3.micro EC2's.  One EC2 is for the "Frontend" and requires ports 22 and 3000 open.  The other EC2 is for the "Backend" and requires ports 22 and 8000 open.

3. In the "Backend" EC2 (Django) clone your source code repository and install `"python3.9", "python3.9-venv", and "python3.9-dev"`

4. Create a python3.9 virtual environment (venv), activate it, and install the dependencies from the "requirements.txt" file.

5. Modify "settings.py" in the "my_project" directory and update "ALLOWED_HOSTS" to include the private IP of the backend EC2.  

6. Start the Django server by running:
```
python manage.py runserver 0.0.0.0:8000
```

7. In the "Frontend" EC2 (React), clone your source code repository and install Node.js and npm by running:
```
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

8. Update "package.json" and modify the "proxy" field to point to the backend EC2 private IP: `"proxy": "http://BACKEND_PRIVATE_IP:8000"`

9. Install the dependencies by running:
```
npm i
```

10. Set Node.js options for legacy compatibility and start the app:
```
export NODE_OPTIONS=--openssl-legacy-provider
npm start
```

11. You should be able to enter the public IP address:port 3000 of the Frontend server in a web browser to see the application.  If you are able to see the products, it sucessfully connected to the backend server!  To see what the application looks like if it fails to connect: Navigate to the backend server and stop the Django server by pressing ctrl+c.  Then refresh the webpage.  You should see that the request for the data in the backend failed with a status code.

12.  Destroy the 2 EC2's from the above steps. Again, this was to help you understand the inner workings of a new application with a new tech stack.

NOTE: What is the tech stack?

### IaC and a CICD pipeline

1. Create an EC2 t3.medium called "Jenkins_Terraform" for Jenkins and Terraform.

2. Create terraform file(s) for creating the infrastructure outlined below:

```
- 1x Custom VPC named "wl5vpc" in us-east-1
- 2x Availability zones in us-east-1a and us-east-1b
- A private and public subnet in EACH AZ
- An EC2 in each subnet (EC2s in the public subnets are for the frontend, the EC2s in the private subnets are for the backend) Name the EC2's: "ecommerce_frontend_az1", "ecommerce_backend_az1", "ecommerce_frontend_az2", "ecommerce_backend_az2"
- A load balancer that will direct the inbound traffic to either of the public subnets.
- An RDS databse (See next step for more details)
```
NOTE 1: This list DOES NOT include ALL of the resource blocks required for this infrastructure.  It is up to you to figure out what other resources need to be included to make this work.

NOTE 2: Remember that "planning" is always the first step in creating infrastructure.  It is highly recommeded to diagram this infrastructure first so that it can help you organize your terraform file.

NOTE 3: Put your terraform files into your GitHub repo in the "Terraform" directory. 

3. To add the RDS database to your main.tf, use the following resource blocks:

```
resource "aws_db_instance" "postgres_db" {
  identifier           = "ecommerce-db"
  engine               = "postgres"
  engine_version       = "14.13"
  instance_class       = var.db_instance_class
  allocated_storage    = 20
  storage_type         = "standard"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres14"
  skip_final_snapshot  = true

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "Ecommerce Postgres DB"
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_subnet_group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "RDS subnet group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.ecommerce_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS Security Group"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.postgres_db.endpoint
}

```
NOTE: Modify the above resource blocks as needed to fit your main.tf file.

  you can either hard code the db_name, username, password or use the varables:

```
variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "ecommercedb"
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "kurac5user"
}

variable "db_password" {
  description = "Password for the master DB user"
  type        = string
  default     = "kurac5password"
}
```
NOTE: DO NOT CHANGE THE VALUES OF THE VARIABLES!

4. Edit the Jenkinsfile with the stages: "Build", "Test", "Init", "Plan", and "Apply" that will build the application, test the application (tests have already been created for this workload- the stage just needs to be edited to activate the venv and paths to the files checked), and then run the Terraform commands to create the infrastructure and deploy the application.

Note 1: You will need to create scripts that will run in "User data" section of each of the instances that will set up the front and/or back end servers when Terraform creates them.  Put these scripts into a "Scripts" directory in the GitHub Repo.

Note 2: Recall from the first section of this workload that in order to connect the frontend to the backend you needed to modify the settings.py file and the package.json file.  This can be done manually after the pipeline finishes OR can be automated in the pipeline with the following commands:

`sed -i 's/ALLOWED_HOSTS = \[\]/ALLOWED_HOSTS = \["your_ip_address"\]/' settings.py`

`sed -i 's/http:\/\/private_ec2_ip:8000/http:\/\/your_ip_address:8000/' package.json`

where `your_ip_address` is replaced with the private IP address of the backend server.  

HINT: You will need to OUTPUT the private IP address and somehow replace the 'your_ip_address' value with what was output. Again, this is optional for those who want to figure it out and create a completely automated process.

Note 3: In order to connect to the RDS database: You will need to first uncomment lines 88-95 of the settings.py file.  The values for the keys: "NAME", "USER", "PASSWORD", "HOST" can again, be configured manually after the infrastructure is provisioned OR automatically as was done above.

Note 4: To LOAD THE DATABASE INTO RDS, the following commands must be run (Hint: in a script or a stage): 
```
#Create the tables in RDS: 
python manage.py makemigrations account
python manage.py makemigrations payments
python manage.py makemigrations product
python manage.py migrate

#Migrate the data from SQLite file to RDS:
python manage.py dumpdata --database=sqlite --natural-foreign --natural-primary -e contenttypes -e auth.Permission --indent 4 > datadump.json

python manage.py loaddata datadump.json
```

Note 5: Notice lines 33, 34, and 36 of the Jenkinsfile.  You will need to use AWS IAM credentials for this account to use terraform.  However, you cannot upload those credentials to GitHub otherwise your account will be locked immediately.  Again: DO NOT EVER UPLOAD YOUR AWS ACCESS KEYS TO GITHUB OR YOUR ACCOUNT WILL BE LOCKED OUT IMMEDIATELY! (notify an insructor if this happens..).  In order to use your keys, you will need to use Jenkins Secret Manager to store credentials.  Follow the following steps to do so:

1. Create a multibranch pipeline called "Workload_5" and connect your GitHub account.

2. AFTER adding your GitHub credentials (with or without saving the multibranch pipeline), navigate to the Jenkins Dashboard and click on "Manage Jenkins" on the left navagation panel.

3. Under "Security", click on "Credentials".

4. You should see the GitHub credentials you just created here.  On that same line, click on "System" and them "Global credentials (unrestricted)". (You should see more details about the GitHub credentials here (Name, Kind, Description))

5. Click on "+ Add Credentials"

6. In the "Kind" Dropdown, select "Secret Text"

7. Under "Secret", put your AWS Access Key.

8. Under "ID", put "AWS_ACCESS_KEY" (without the quotes)

9. Repeat steps 5-8 with your secret access key as "AWS_SECRET_KEY".

Note 1: What is this doing? How does this all translate to terraform being able provision infrastructure?

Note 2: MAKE SURE THAT YOUR main.tf HAS VARIABLES DECLARED FOR `aws_access_key` AND `aws_secret_key`! THERE SHOULD BE NO VALUE TO THESE VARIABLES IN ANY OF THE FILES!

Note 3: You can do this with the RDS password as well.  The "terraform plan" command will need to be modified to accomodate any variable that was declared but has no value.

5. Run the Jenkins Pipeline to create and deploy the infrastructure and application!

5. Create a monitoring EC2 called "Monitoring" in the default VPC that will monitor the resources of the various servers.  (Hopefully you read through these instructions in it's entirety before you ran the pipeline so that you could configure the correct ports for node exporter.)

6. Document! All projects have documentation so that others can read and understand what was done and how it was done. Create a README.md file in your repository that describes:

	  a. The "PURPOSE" of the Workload,

  	b. The "STEPS" taken (and why each was necessary/important),
    
  	c. A "SYSTEM DESIGN DIAGRAM" that is created in draw.io (IMPORTANT: Save the diagram as "Diagram.jpg" and upload it to the root directory of the GitHub repo.),

	  d. "ISSUES/TROUBLESHOOTING" that may have occured,

```
* Proxy error: Could not proxy request /api/products/ from 44.211.212.52:3000 to http://10.0.1.92:8000.
See https://nodejs.org/api/errors.html#errors_common_system_errors for more information (ECONNREFUSED).
```

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

  e. An "OPTIMIZATION" section for how you think this workload/infrastructure/CICD pipeline, etc. can be optimized further.  

  f. A "BUSINESS INTELLIGENCE" section for the questions below,

  g. A "CONCLUSION" statement as well as any other sections you feel like you want to include.

## Business Intelligence

The database for this application is not empty.  There are many tables but the following are the ones to focus on: "auth_user", "product", "account_billing_address", "account_stripemodel", and "account_ordermodel"

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

How you choose to run these queries is up to you.  You can run them in the terminal, a python script, a jupyter notebook, etc.  

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

Questions: 

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

Provide the SQL query used to gather this information as well as the answer.

