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

Questions: 

1. Create a diagram of the schema and relationship between the tables (keys). (Use draw.io for this question)

2. How many rows of data are there in these tables?  What is the SQL query you would use to find out how many users, products, and orders there are?

3. Which states ordered the most products? Least products? Provide the top 5 and bottom 5 states.

4. Of all of the orders placed, which product was the most sold? Please prodide the top 3.

Provide the SQL query used to gather this information as well as the answer.

