#!/usr/bin/env bash

TMPDIR=${HOME}
rm -rf $TMPDIR/invars $TMPDIR/outvars $TMPDIR/blockedvarnames $TMPDIR/invarnames $TMPDIR/outvarnames $TMPDIR/source.vars $TMPDIR/varnames

export -n > $TMPDIR/invars

groupmod -g ${DOCKER_GID} docker
usermod -a -G ${DOCKER_GID} -u ${GRADLE_UID} gradle
chown gradle $TMPDIR/invars

sudo -i -u gradle bash << EOF
export -n > $TMPDIR/outvars
EOF

BLOCKED_VARS=(HOME USER PWD SHELL LOGNAME USERNAME)
printf "%s\n" "${BLOCKED_VARS[@]}" > $TMPDIR/blockedvarnames

cat $TMPDIR/invars | sed -E 's/^declare\ -x\ //' | sed -E 's/=/*/' | cut -d '*' -f 1 > $TMPDIR/invarnames
cat $TMPDIR/outvars | sed -E 's/^declare\ -x\ //' | sed -E 's/=/*/' | cut -d '*' -f 1 > $TMPDIR/outvarnames

chown gradle $TMPDIR/invarnames
chown gradle $TMPDIR/outvarnames

cat $TMPDIR/outvarnames $TMPDIR/blockedvarnames > $TMPDIR/outvarnames
grep -F -x -v -f $TMPDIR/outvarnames $TMPDIR/invarnames > $TMPDIR/varnames
grep -F -f $TMPDIR/varnames $TMPDIR/invars > source.vars

chown gradle $TMPDIR/blockedvarnames
chown gradle $TMPDIR/varnames
chown gradle source.vars

mkdir /run/sshd && /usr/sbin/sshd

sudo -i -u gradle bash << EOFF

echo "source source.vars" >> /home/gradle/.bashrc
echo "export GRADLE_USER_HOME=\${HOME}" >> /home/gradle/.bashrc

TMPDIR=${HOME}
rm -rf $TMPDIR/invars $TMPDIR/outvars $TMPDIR/blockedvarnames $TMPDIR/invarnames $TMPDIR/outvarnames $TMPDIR/source.vars $TMPDIR/varnames

ssh-keyscan -H github.com >> ~/.ssh/known_hosts

sleep infinity

EOFF