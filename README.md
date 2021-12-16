# Magic 8-Ball Web App

### Created by Jordan Ricks

<br>

## Description
This is a VueJS magic 8-ball web application hosted in an AWS S3 bucket. You can check it out yourself by visiting [8-ball.ml](https://www.8-ball.ml).

I origianally created this project as a way to teach others about AWS serverless technology such as API Gateway, S3, and Lambda. It served as a simple and effective begginer project. Since then, I have recreated the project in Terraform (IAC) and configured the website to be fully public facing with cloudfront.

![](./pictures/Website.png)

<br>

## Technologies Used
- VueJS
- NodeJS
- AWS S3
- AWS API Gateway
- AWS Route 53
- AWS Certificate Manager
- AWS Lambda
- AWS Cloudfront
- AWS IAM
- Python
- Terraform
- Github Actions

<br>

## How it Works

![](./pictures/Diagram.jpeg)

When somebody types "8-ball.ml" into their browser the DNS returns the address of Cloudfront. Cloudfront attaches the SSL Certificate to the website and serves the website through the S3 bucket. When the "Shake" button is pushed, an http post request is sent to API Gateway, which forwards the request directly to our lambda. The lambda selects a random response from a list of responses and passes it back through API Gateway to our website. VueJS will dynamically update the webpage to display the answer.

<br>

## Lessons Learned
When I first started this project I did not realize all that went into hosting a public website. However, delving into this project has helped me understand how DNS works, the difference between record types, configuring IAM users, and how CI/CD pipelines work. This project took longer than I had originally hoped, but I have learned much because of it.

When I ran into road blocks I often was able to find solutions by searching for solutions on the internet. However, there were a few times where I could not find the right solution on the internet. I am fortunate enough to work around other highly talented people who were gracious enough to offer their help.

<br>

## Create your own serverless website!
So, you want to set up your very own magic 8-ball website? Well, your in luck! Below you will find a step-by-step guide to do just that! I've taken out a lot of the tedious work, and best of all it only costs about 50¢ per month!

Note: A prerequisite for this project is to have NodeJS and VueJS already installed. If you do not already have these packages, take some time to install them before continuing.

### 1. Create an AWS account
To create your own AWS account go to [aws.amazon.com](https://aws.amazon.com). Click the "Sign in to the console" button in the top right corner. On the next page click "Create a new AWS account" and follow the instructions to create your account.

### 2. Get domain name
To create a public facing website you probably want a pretty looking url. Freenom.com allows you to register a custom domain name for free for 12 months on a select few top level domains.

In a new tab navigate to [freenom.com](https://www.freenom.com) and find a domain for your website. Once you find an available domain go through the registration process. Once the registration is complete you can view your domains by clicking on the Services tab and selecting "My Domains". Keep this page open, as we will need to grab some details from here for the next step.

### 3. Create a hosted zone
Switch back to the AWS console and search for Route 53. Create a new hosted zone with the domain name you registered in the previous step and push "Create hosted zone".

You will find that two record were create in your zone by default. A Start of Authority record (SOA), and a Name Server record (NS). Next we need to add the NS records into freenom.

On freenom under <b>My Domains</b>, click <b>Manage Domain</b>, then <b>Managment Tools</b>, then <b>Nameservers</b>. Select <b>Use custom nameservers</b> and copy over the values from the NS record in your AWS account. This tells freenom to send traffic for your domain to your AWS account.

### 4. Create a user for GitHub Actions
Next we will need to create a user that has the correct permissions to allow GitHub Actions to deploy resources into our AWS account. In the AWS console navigate to the IAM console and add a new user. Make sure the access type selected is <b>Access key - Programatic Access</b>. On the next step we need to add the user's permissions. Under <b> Attach existing policies directly</b> select <b>AdministratorAccess</b> and push next. Finally create the user.

You will be given an <b>Access key ID</b> and <b>Secret access key</b> for your new user. Stay on this page, because in the next step we need to enter these credentials into GitHub.

### 5. Set up your repo
If you haven't already cloned this repo, go ahead and clone it to your own repo. In your repo settings select the <b>Secrets</b> tab. Create two new secrets, one for the client id and one for the secret. Name them whatever you like, just be sure to distinguish them from each other.

### 6. Create a bucket and table for terraform
Terraform is how we have defined all of our infrastructure as code (IAC). To keep track of its state we need to create an S3 bucket and a DynamoDB table.

Navigate to the S3 console in AWS and create a new bucket. Name it "terraform-state-storage-{account number}" or something similar. Leave the other settings as default.

Next nevigate to the DynamoDB console and create a new table. Name it "terraform-state-lock-{account number}" or something similar. Set the partition key to "LockID". Select <b>Customize settings</b>. Change read and write capacity to <b>On-Demand</b>. Leave everything else as default and create the table.

### 7. Lets change some things
We are so close to deploying our website! The last thing we have to do is make some changes in the code.

First we need to tell our website where to send api calls. (The api will automatically be created when we push our code to GitHub.) Go to <b>src > components > Shake.vue</b>. Edit line 67 to be the address of the domain you created with https://api. at the beginning and /shake on the end. API calls will be sent to the this api subdomain.

For example:
```
https://api.8-ball.ml/shake
```

Next we need to set some variables so that our resources get deployed correctly. Go to <b>terraform > trn > app > main.tf</b>. Here you will find some of the infrastructure as code (IAC) which defines the resources to deploy our website. In this file we need to define our terraform bucket (Line 5), terraform dynamo table (Line 7), account number (line 31), the domain name (line 33), and the hosted zone id (line 35). Change these values to your own. (You can find your hosted zone id in route 53 in the AWS console.)

When you push code to your repository, github looks for a .yml file in the <b>.github > workflows</b> directory. This is where the actions are defined GitHub Actions. In this file we need to change the credentials to the name of our secrets in our repo. On line 28 and 29 change the vlaue to be the name of your secret. 

For example:
```
${{ secret.my_client_id }}
${{ secret.my_secret }}
```

### 8. Build
Any time we update our website files (ie. shake.vue), we need to compile the code for production before we push it up into GitHub. To do this open up a termial at the root of this repo. Run the following command:
```
npm run build
```

### 9. Deploy!
Once the build is complete, the last thing to do is push your code up to github.
Push your code, then quickly navigate to the <b>Actions</b> tab on GitHub. Here you should see your deployment. Click on the deployment to see the log output. Once the action completes succesfully, the website has been fully built!

Navigate to your domain and you should be greeted by the magic 8-ball.
Ask the 8-ball a question and push shake. You should recieve an answer within a second or two.

Congragulations! You have created your very own AWS account, registered your own domain for free, and set up a CI/CD pipline using Terraform and GitHub Actions.

<br>
<br>


## Resources
[FreeNom.com](https://freenom.com) - Register a domain name for free for a year