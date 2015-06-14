#!/bin/bash

#set -x
set -e

INIT_CONF=0
CONTINUE_BACKUP=0
if [ -z "$1" ]; then
  BACKUP_DATE=`date "+%Y-%m-%dT%H-%M-%S"`
else
  if [ "$1" == "init" ]; then
    INIT_CONF=1
  else
    BACKUP_DATE="$1"
    CONTINUE_BACKUP=1
  fi
fi

if [ ! -d "$HOME" ]; then
  echo "Env variable '\$HOME' not found."
  exit 1
fi

CONF_DIR="$HOME/.backup-mj41cz"

if [ "$INIT_CONF" == 1 ]; then
  if [ -d "$CONF_DIR" ]; then
    echo "Can't initialize. Directory '$CONF_DIR' already exists."
    exit 1
  fi
  mkdir "$CONF_DIR"
  echo ".cache/" > "$CONF_DIR/exclude.list"

  echo "#!/bin/bash" >> "$CONF_DIR/config.sh"
  echo "" >> "$CONF_DIR/config.sh"
  echo "BACKUP_WHAT=$HOME" >> "$CONF_DIR/config.sh"
  echo "BACKUP_WHERE=/run/media/mj/backup-medium/backup-mj41cz" >> "$CONF_DIR/config.sh"

  ls -al "$CONF_DIR/"
  head -n1000 $CONF_DIR/*
  echo
  echo "Default backup-mj41cz configuration created inside '$CONF_DIR/'."
  echo "Please edit these files for you needs !"
  exit 0
fi

if [ ! -d "$CONF_DIR" ]; then
  echo "Congiguration directory '$CONF_DIR' not found."
  echo "Run '$0 init' to initialize configuration files."
  exit 1
fi

source $CONF_DIR/config.sh

if [ ! -d "$BACKUP_WHAT" ]; then
  echo "Directory to backup '$BACKUP_WHAT' (\$BACKUP_WHAT) not found."
  exit 1
fi

if [ ! -d "$BACKUP_WHERE" ]; then
  echo "Backup destination directory '$BACKUP_WHERE' (\$BACKUP_WHERE) not found."
  exit 1
fi

INCOMPLETE_BACKUP_DIR="$BACKUP_WHERE/incomplete-$BACKUP_DATE"
if [ "$CONTINUE_BACKUP" == 1 ]; then
  if [ ! -d "$INCOMPLETE_BACKUP_DIR" ]; then
    echo "Parameter '$BACKUP_DATE' was interpreted as backup date, but directory with incomplete"
    echo "backup '$INCOMPLETE_BACKUP_DIR' not found."
    exit 1
  fi
fi

FIRST_BACKUP=1
if [ -L "$BACKUP_WHERE/current" ]; then
  FIRST_BACKUP=0
fi

echo "BACKUP_DATE: '$BACKUP_DATE'"
echo "BACKUP_WHAT: '$BACKUP_WHAT'"
echo "BACKUP_WHERE: '$BACKUP_WHERE'"
echo "FIRST_BACKUP: '$FIRST_BACKUP'"
echo ""

if [ "$FIRST_BACKUP" == 1 ]; then
  rsync -azP \
      --delete \
      --delete-excluded \
      --exclude-from=$CONF_DIR/exclude.list \
      $BACKUP_WHAT/ $INCOMPLETE_BACKUP_DIR \
    && mv $BACKUP_WHERE/incomplete-$BACKUP_DATE/ $BACKUP_WHERE/back-$BACKUP_DATE \
    && ln -s $BACKUP_WHERE/back-$BACKUP_DATE/ $BACKUP_WHERE/current
  ERR_CODE=$?
else
  rsync -azP \
      --delete \
      --delete-excluded \
      --exclude-from=$CONF_DIR/exclude.list \
      --link-dest=$BACKUP_WHERE/current \
      $BACKUP_WHAT/ $INCOMPLETE_BACKUP_DIR \
    && mv $BACKUP_WHERE/incomplete-$BACKUP_DATE/ $BACKUP_WHERE/back-$BACKUP_DATE/ \
    && rm -f $BACKUP_WHERE/current \
    && ln -s $BACKUP_WHERE/back-$BACKUP_DATE/ $BACKUP_WHERE/current
  ERR_CODE=$?
fi
echo ""

echo "BACKUP_DATE: '$BACKUP_DATE'"
echo "BACKUP_WHAT: '$BACKUP_WHAT'"
echo "BACKUP_WHERE: '$BACKUP_WHERE'"
echo "FIRST_BACKUP: '$FIRST_BACKUP'"
echo ""

if [ "$ERR_CODE" != 0 ]; then
  echo ""
  echo "Backup failed. Current state of backup directory:"
  ls -al $BACKUP_WHERE
  echo ""
  echo "Backup of '$BACKUP_WHAT' to '$BACKUP_WHERE' failed with error code '$ERR_CODE'."
  echo "You can find incomplete backup inside '$INCOMPLETE_BACKUP_DIR'."
  echo "Remove this directory or try to fix problem and run '$0 $BACKUP_DATE' to continue backup."
  exit 1
fi

echo "Backup of '$BACKUP_WHAT' to '$BACKUP_WHERE' finished ok."
exit 0
