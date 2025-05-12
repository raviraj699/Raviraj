#To run this script periodically or for multiple instances, you can:

#Cron Job: Schedule the script using crontab (e.g., 0 2 * * * /path/to/delete_rds_instance.sh for daily execution at 2 AM).
#Loop

DB_INSTANCES=("db1" "db2" "db3")
for DB_INSTANCE_IDENTIFIER in "${DB_INSTANCES[@]}"; do
  check_db_instance
  disable_deletion_protection
  delete_db_instance
done
