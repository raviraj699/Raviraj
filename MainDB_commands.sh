1> aws rds describe-db-instances <Db-instance-identifier> ## List's Db instances based on identifier, if there are no identifier's provided it will list all db. Name of DB not identifier
2> To find the particular DB in the rds "aws rds describe-db-instances --db-instance-identifier <Identity-fier> --region <region>"
Diffrence between Endpoint and idendinetifier : 
Endpoint : mydbinstance.ch820uu2q5wo.ap-south-1.rds.amazonaws.com 
Identity-fier: mydbinstance
3> Describe Db-subnet-group: aws rds describe-db-subnet-groups
what is the diffrence between subnet and DB-subnet.

Describe Vpc: aws ec2 describe-vpcs

To create DB :
aws rds create-db-subnet-group \
    --db-subnet-group-name my-subnet-group \
    --db-subnet-group-description "My DB subnet group" \
    --subnet-ids subnet-03d9200406ddbf916 subnet-0fa500086c3b2b477


aws rds create-db-instance \
    --db-instance-identifier mydbinstance \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --master-username admin \
    --master-user-password password123 \
    --allocated-storage 20 \
    --backup-retention-period 7 \
    --no-multi-az \
	--db-subnet-group-name my-subnet-group \
    --vpc-security-group-ids sg-06629d317c64f32cf


    aws ec2 create-security-group \
    --group-name MySecurityGroup \
    --description "My security group description" \
    --vpc-id vpc-00ad5a0373f560847 \
    --region ap-south-1


aws ec2 describe-security-groups --group-ids sg-06629d317c64f32cf
aws rds describe-db-subnet-groups --db-subnet-group-name my-subnet-group











Db-parameter: 

create-db-instance
[--db-name <value>]
--db-instance-identifier <value>
[--allocated-storage <value>]
--db-instance-class <value>
--engine <value>
[--master-username <value>]
[--master-user-password <value>]
[--db-security-groups <value>]
[--vpc-security-group-ids <value>]
[--availability-zone <value>]
[--db-subnet-group-name <value>]
[--preferred-maintenance-window <value>]
[--db-parameter-group-name <value>]
[--backup-retention-period <value>]
[--preferred-backup-window <value>]
[--port <value>]
[--multi-az | --no-multi-az]
[--engine-version <value>]
[--auto-minor-version-upgrade | --no-auto-minor-version-upgrade]
[--license-model <value>]
[--iops <value>]
[--option-group-name <value>]
[--character-set-name <value>]
[--nchar-character-set-name <value>]
[--publicly-accessible | --no-publicly-accessible]
[--tags <value>]
[--db-cluster-identifier <value>]
[--storage-type <value>]
[--tde-credential-arn <value>]
[--tde-credential-password <value>]
[--storage-encrypted | --no-storage-encrypted]
[--kms-key-id <value>]
[--domain <value>]
[--domain-fqdn <value>]
[--domain-ou <value>]
[--domain-auth-secret-arn <value>]
[--domain-dns-ips <value>]
[--copy-tags-to-snapshot | --no-copy-tags-to-snapshot]
[--monitoring-interval <value>]
[--monitoring-role-arn <value>]
[--domain-iam-role-name <value>]
[--promotion-tier <value>]
[--timezone <value>]
[--enable-iam-database-authentication | --no-enable-iam-database-authentication]
[--database-insights-mode <value>]
[--enable-performance-insights | --no-enable-performance-insights]
[--performance-insights-kms-key-id <value>]
[--performance-insights-retention-period <value>]
[--enable-cloudwatch-logs-exports <value>]
[--processor-features <value>]
[--deletion-protection | --no-deletion-protection]
[--max-allocated-storage <value>]
[--enable-customer-owned-ip | --no-enable-customer-owned-ip]
[--custom-iam-instance-profile <value>]
[--backup-target <value>]
[--network-type <value>]
[--storage-throughput <value>]
[--manage-master-user-password | --no-manage-master-user-password]
[--master-user-secret-kms-key-id <value>]
[--ca-certificate-identifier <value>]
[--db-system-id <value>]
[--dedicated-log-volume | --no-dedicated-log-volume]
[--multi-tenant | --no-multi-tenant]
[--engine-lifecycle-support <value>]
[--cli-input-json <value>]
[--generate-cli-skeleton <value>]
[--debug]
[--endpoint-url <value>]
[--no-verify-ssl]
[--no-paginate]
[--output <value>]
[--query <value>]
[--profile <value>]
[--region <value>]
[--version <value>]
[--color <value>]
[--no-sign-request]
[--ca-bundle <value>]
[--cli-read-timeout <value>]
[--cli-connect-timeout <value>]
