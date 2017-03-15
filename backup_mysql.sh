#!/bin/sh

MYSQL_USER="root"
MYSQL_PASSWORD="xxxxxx"

MYSQL_DB="mysql tlog3 acccount"


BACKUP_ROOT="/backup/mysql"
BACKUP_LOG="/var/log/backup-mysql.log"

BACKUP_SERVICE="MySQL-Daily"
BACKUP_START=$(date +"%F %T")


HOSTNAME=$(hostname -s)

###################################
DELETE_DATE=$(date --date='1 months ago' +%Y%m%d)
DELETE_PATH=$BACKUP_ROOT/

BACKUP_DATE=$(date +"%Y%m%d")
BACKUP_PATH=$BACKUP_ROOT/$BACKUP_DATE
MYSQL_CMD="/usr/bin/mysql -u $MYSQL_USER -p$MYSQL_PASSWORD"
MYSQL_DUMP="/usr/bin/mysqldump -u $MYSQL_USER -p$MYSQL_PASSWORD"


if [ ! -z $1 ];
then
	BACKUP_ROOT="$BACKUP_ROOT-$1"
fi

echo "-----------------------------------------------------------------" >> $BACKUP_LOG
echo "Starting backup $BACKUP_DATE" >> $BACKUP_LOG
echo "" >> $BACKUP_LOG

echo -n " * Delete expire date..." >> $BACKUP_LOG
if [ -d $DELETE_PATH ]; then
	rm -rf $DELETE_PATH
fi
echo "done" >> $BACKUP_LOG

for DB_NAME in $MYSQL_DB
do
	BACKUP_PATH_NEW=$BACKUP_PATH/$DB_NAME
	echo -n " * Checking backup directory..." >> $BACKUP_LOG
	if [ ! -d $BACKUP_PATH_NEW ]; then
		mkdir -p $BACKUP_PATH_NEW
	fi
	echo "done" >> $BACKUP_LOG


	echo -n " * Fetch $DB_NAME tables..." >> $BACKUP_LOG
	tables=$(echo "SHOW TABLES" | $MYSQL_CMD $DB_NAME | grep -v "^Table")
	echo "done" >> $BACKUP_LOG


	echo " * Optimize tables..." >> $BACKUP_LOG
	for table in $tables
	do
		echo -n "   - $DB_NAME.$table." >> $BACKUP_LOG
		echo "REPAIR TABLE \`$table\`" | $MYSQL_CMD $DB_NAME >/dev/null
		echo -n "." >> $BACKUP_LOG
		echo "OPTIMIZE TABLE \`$table\`" | $MYSQL_CMD $DB_NAME >/dev/null
		echo "done" >> $BACKUP_LOG
	done

	echo " * Starting dump database..." >> $BACKUP_LOG
	# Backup
	for table in $tables
	do
		echo -n "   - $DB_NAME.$table." >> $BACKUP_LOG
		$MYSQL_DUMP $DB_NAME $table > $BACKUP_PATH_NEW/$table.sql

		#echo -n "." >> $BACKUP_LOG
		#gzip $BACKUP_PATH_NEW/$table.sql
		echo "done" >> $BACKUP_LOG
	done
done

echo "Backup end" >> $BACKUP_LOG
