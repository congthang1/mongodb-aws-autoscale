# MongoDB Automatic Scale on AWS
AWS Cloudformation template for MongoDB with replica sets and Automatic Scale, support running on spot instance and ARM architecture.

# Code of conduct
## Replica Resources:
  This deployment is creating A MongoDB cluster including 3 replicas. Each replica is set of resource:
  - 01 EC2 Autoscale Group (1 instance).
  - 01 Service on Elastic Container Services.
  - 01 EBS volume.
  - 01 Service Discovery Endpoint.
## Working flow
  - Everytime create or updating, scaling, the order is replica 03 > replica 02 > replica 01.
  - Priority of becoming Primary is Replica 01: 3, replica 02: 2, replica 01: 1. Replica 01 always try to to become primary at the end of updating.
  - Each replica is self repairing, when it fail or unhealthy, the replacement is initiated and bring it back to healthy. This is managed by ECS service deployment and EC2 autoscaling group. Even if you using Spot Instance (reduce up to 90% of cost), the Spot interuption is handled by autoscale group.

## Auto Scaling
- A set of 2 alarms Low cpu and High cpu usage is added to Autoscale Group of Replica 01. When alarm fired, it is creating a SNS signal on SNS topic, SNS then trigger the Lambda scaling script to update cloudformation stack to update new instance type to higher if scale up or lower if scale down. The instance is replacing from replica 03 > 02 > 01, the scaling is ideally with zero downtime.
  
# The Benefit
- 1 click deploy a high availability MongoDB Cluster.
- Control over your database data with your MongoDB instead of using other providers.
- Reduce upto 90% of cost in comparison with using a managed mongodb from other providers.
- Easy monitoring with ECS metrics and CloudWatch.
- Keep everything safe under your private network on AWS Infrastructure.
- Eliminate data transfer cost out of AWS Services.
- Ability to use ARM architecture with higher Performance/price.
- Ability to use Spot Instance (reduce up to 90% instance cost).
- Ensuring high availability and auto scale at high demand spike.
  
# Preparing for deployment
1. Create 3 EBS volume that will use for each mongo replica. The volume must be already formated (sudo mkfs -t xfs);
2. Create AWS ECS Cluster or use an existing cluster name;
3. Create a security group allow connecting between replica on port 27017 and to your application;
4. Create a Service Discovery private Endpoint on AWS cloudmap with your VPC or reuse an existing priate endpoint;
5. Create a Lamda IAM role with cloudwatch putlog permission;
6. Create an ssh key pair name or resue an existing ssh key name, download this keypair and copy to the ./docker folder;
7. Create or reuse an aws cli account (keyId and secret). This account must have permissions:
   - Attach/describe EBS volume to instance;
   - Refresh instance on EC2 autoscale group;
   - Update Cloudformation stack;
8. Create MongoDB keyfile for replica communication tls.

  `    
      chmod a+x 400 ./generate-keyfile.sh && ./generate-keyfile.sh
  `

9. Build docker file and push to your docker repository.
# Results
Mongo Connection URI with replica will be:

`  
  mongodb://mongouser:mongopass@DBNAME-01.service-discovery-name,DBNAME-02.service-discovery-name,DBNAME-03.service-discovery-name/?authSource=admin
`
# Backup and restore
Its recommended to use AWS backup plan to backup the First replica (replica 01) volume. Restore a backup just by put new volumeid to new deployment.

