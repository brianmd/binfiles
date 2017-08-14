#!/bin/sh
policy=${HOME}/.config/jstatd.all.policy
# grant codebase "file:/usr/lib/jvm/java-8-oracle/lib/tools.jar" {
[ -r ${policy}  ] || cat >${policy} <<'POLICY'
grant codebase "file:${java.home}/../lib/tools.jar" {
  permission java.security.AllPermission;
};
POLICY

# jstatd -J-Djava.security.policy=${policy} &
jstatd -J-Djava.security.policy=${policy} -J-Djava.rmi.server.logCalls=true

