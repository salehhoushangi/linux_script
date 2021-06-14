#!/bin/bash

##hardening linux
####1
echo "###1" ######Filesystem Configuration
echo "Ensure /tmp is configured and nodev,nosuid and noexec options set on /tmp is enabled ####"
if [ "$(mount | grep -E '\s/tmp\s')" == "tmpfs on /tmp type tmpfs (rw,nosuid,nodev,noexec,relatime)" ];then 
    echo "/tmp is mounted on legal accessibility >>>> ok"
else 
    echo "/tmp is'nt mounted on legal accessibility >>>> not ok " 
fi
echo "Ensure tmpfs has been mounted to, or a system is enabled #####"
if [ "$(grep -E '\s/tmp\s' /etc/fstab | grep -E -v '^\s*#')" == "tmpfs /tmp tmpfs defaults,noexec,nosuid,nodev 0 0" ];then
    echo "tmpfs is mounted on legal accessibility >>> ok"
else

    echo "tmpfs is'nt  mounted or mounted  on ilegal accessibility >>> not ok  "
fi

echo "Ensure tmp.mount is enabled ######"
if [ "$(systemctl is-enabled tmp.mount)" == "enabled" ];then

    echo "tmp.mount is enable >>> ok "
else
    echo "tmp.mount is not  enable >>> not ok "
fi

####2
echo "#####2"
echo "Ensure sticky bit is set on all world-writable directories ####"
if [ "$(df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null)" == "" ]; then
    echo "No output should be returned  >>> ok"
else
    echo "output returned >>>  not ok"
fi
#####3
echo "#####3" ######Process Hardening
echo "Ensure core dumps are restricted####"
if [ "$(grep "hard core" /etc/security/limits.conf /etc/security/limits.d/*)" == "* hard core 0" ]; then
    echo "* hard core 0>>> ok"
else
    echo "* hard core 0 >>> not ok"
fi
if [ "$(sysctl fs.suid_dumpable)" == "fs.suid_dumpable = 0" ]; then
    echo "fs.suid_dumpable = 0 >>> ok"
else
    echo "fs.suid_dumpable = 0 >>> not ok"
fi

if [ "$( systemctl is-enabled coredump.service 2>/dev/null)" == " systemd-coredump is installed" ]; then
    echo " systemd-coredump is installed>>> ok"
else
    echo " systemd-coredump is not installed>>> not ok"
fi

####4
echo "####4"
echo "Ensure address space layout randomization (ASLR) is enabled"
if [ "$(sysctl kernel.randomize_va_space)" == "kernel.randomize_va_space = 2" ]; then
    echo " kernel.randomize_va_space = 2>>> ok"
else
    echo " kernel.randomize_va_space = 2>>> not ok"
fi
if [ "$( grep "kernel\.randomize_va_space" /etc/sysctl.conf /etc/sysctl.d/*)" == "kernel.randomize_va_space = 2" ]; then
    echo " kernel.randomize_va_space = 2>>> ok"
else
    echo " kernel.randomize_va_space = 2 (sysctld)>>> not ok"
fi
####5
echo "####5" ####OS Hardening and Services
echo "Ensure FTP Server is not enabled"
if [[ "$(systemctl is-enabled vsftpd  2>/dev/null)" == "disabled" || $? == 1  ]]; then
    echo " vsftpd is disabled = 2>>> ok"
else
    echo " vsftpd is enabled >>> not ok"
fi
####6
echo "####6" 
echo "Ensure xinetd is not installed"
if [ "$(rpm -q xinetd)" == "package xinetd is not installed" ]; then
    echo "package xinetd is not installed>>> ok"
else
    echo "package xinetd is installed>>> not ok"
fi
####7
echo "####7"
echo "Ensure DNS Server is not enabled"
if [[ "$(systemctl is-enabled named 2>/dev/null)" == "disabled" || $? == 1  ]]; then
    echo "DNS server is disabled>>> ok"
else
    echo "DNS server is enable>>> not ok"
fi
####8
echo "####8"
echo "Ensure LDAP server is not enabled"
if [[ "$(systemctl is-enabled slapd 2>/dev/null)" == "disabled" || $? == 1  ]]; then
    echo "LDAP server is disabled>>> ok"
else
    echo "LDAP server is enable>>> not ok"
fi
####9
echo "####9"
echo "Ensure Samba is not enabled "
if [[ "$(systemctl is-enabled smb  2>/dev/null)" == "disabled" || $? == 1  ]]; then
    echo "SAMBA server is disabled>>> ok"
else
    echo "SAMBA server is enable>>> not ok"
fi
####10
echo "####10"
echo "Ensure DHCP is not enabled "
if [[ "$(systemctl is-enabled dhcpd 2>/dev/null)" == "disabled" || $? == 1  ]]; then
    echo "DHCP server is disabled>>> ok"
else
    echo "DHCP server is enable>>> not ok"
fi


#####11
echo "####11"
echo "Ensure Nfs is not enabled "
if [[ "$(systemctl is-enabled nfs-server 2>/dev/null)" == "disabled" || $? == 1  ]]; then
    echo "NFS-SERVER server is disabled>>> ok"
else
    echo "NFS-SERVER server is enable>>> not ok"
fi
####12
echo "####12"
echo "Ensure SNMP is not enabled "
if [[ "$(systemctl is-enabled snmpd 2>/dev/null)" == "disabled" || $? == 1  ]]; then
    echo "SNMP server is disabled>>> ok"
else
    echo "SNMP server is enable>>> not ok"
fi
####13
echo "####13"
echo "Ensure chrony is configured (After setting up the Dotin ntp server"
if [ "$(grep -E "^(server|pool)" /etc/chrony.conf)" == "server 172.29.0.42" ]; then
    echo "Time server has been setup>>> ok"
else
    echo "Time server is not setup(with chrony)>>> not ok"
fi
####14
echo "####14" #####User Access & Passwords

cat /etc/passwd | awk -F: '$3 >= 1000 {print $1, $6 }' |
while read -r user directory; do
    if [ ! -d "$directory" ]; then
        echo "$user"
    fi
done
if [[ $? == $user ]]; then 

    echo "$user has not directory >>> not ok"
else
    echo "ALL created user(sbin/login) have directory>>> ok"
fi

####15
echo "####15"
echo "Ensure password creation requirements are configured"
if [ "$(grep pam_pwquality.so /etc/pam.d/system-auth /etc/pam.d/password-auth)" == "/etc/pam.d/system-auth:password requisite pam_pwquality.so try_first_pass
local_users_only enforce-for-root retry=3
/etc/pam.d/password-auth:password requisite pam_pwquality.so try_first_pass
local_users_only enforce-for-root retry=3
" ]; then
    echo "password has been set>>> ok"
else
    echo "passowrd has some problem>>> not ok"
fi

if [ "$(grep ^minlen /etc/security/pwquality.conf)" == "12" ]; then
    echo "minimum password policy set to 12>>> ok"
else
    echo "No minumum password policy found>>> not ok"
fi
if [ "$(grep ^minclass /etc/security/pwquality.conf)" == "yes" ]; then
    echo " password complexity policy has been set>>> ok"
else
    echo " password complexity policy has not  been set>>> not ok"
fi
####16
echo "####16"
echo "Ensure sudo is installed"
if [ "$(rpm -q sudo)" == "sudo-1.8.23-4.el7.x86_64" ]; then
    echo "Sudo Rpm is installed >>> ok"
else
    echo "Sudo Rpm is not installed >>> not ok"
fi
####17
echo "####17"
echo "Ensure sudo log file exists"
if [ "$(grep -Ei '^\s*Defaults\s+([^#]+,\s*)?logfile=' /etc/sudoers /etc/sudoers.d/*)" == "/etc/sudoers:Defaults logfile=/var/log/sudo" ]; then
    echo "Sudo log path >>> ok"
else
    echo "Sudo log path>>> not ok"
fi


#ardalan

####18
echo "####18"
echo "Ensure IP forwarding is disabled ####"
if [ "$(sysctl net.ipv4.ip_forward)" == "net.ipv4.ip_forward = 0" ]; then
    echo "net.ipv4.ip_forward >>> ok"
else
    echo "net.ipv4.ip_forward >>> not ok"
fi

if [ "$( grep -E -s "^\s*net\.ipv4\.ip_forward\s*=\s*1" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf)" == "" ]; then
    echo "No value  returned >>> ok"
else
    echo "No value  returned >>> not ok"
fi

####19
echo "####19"
echo "Ensure packet redirect sending is disabled ####"
if [ "$(sysctl net.ipv4.conf.all.send_redirects)" == "net.ipv4.conf.all.send_redirects = 0" ]; then
    echo "net.ipv4.conf.all.send_redirects >>> ok"
else
    echo "net.ipv4.conf.all.send_redirects >>> not ok"
fi

if [ "$(sysctl net.ipv4.conf.default.send_redirects)" == "net.ipv4.conf.default.send_redirects = 0" ]; then
    echo "net.ipv4.conf.default.send_redirects >>> ok"
else
    echo "net.ipv4.conf.default.send_redirects >>> not ok"
fi

if [ "$(grep "net\.ipv4\.conf\.all\.send_redirects" /etc/sysctl.conf /etc/sysctl.d/*)" == "net.ipv4.conf.all.send_redirects = 0" ]; then
    echo "net.ipv4.conf.all.send_redirects >>> ok"
else
    echo "net.ipv4.conf.all.send_redirects >>> not ok"
fi

if [ "$(grep "net\.ipv4\.conf\.default\.send_redirects" /etc/sysctl.conf /etc/sysctl.d/*)" == "net.ipv4.conf.default.send_redirects= 0" ]; then
    echo "net.ipv4.conf.default.send_redirects >>> ok"
else
    echo "net.ipv4.conf.default.send_redirects >>> not ok"
fi
####20
echo "####20"
echo "Ensure source routed packets are not accepted ####"

if [ "$(sysctl net.ipv4.conf.all.accept_source_route)" == "net.ipv4.conf.all.accept_source_route = 0" ]; then
    echo "net.ipv4.conf.all.accept_source_route >>> ok"
else
    echo "net.ipv4.conf.all.accept_source_route >>> not ok"
fi

if [ "$(sysctl net.ipv4.conf.default.accept_source_route)" == "net.ipv4.conf.default.accept_source_route = 0" ]; then
    echo "net.ipv4.conf.default.accept_source_route >>> ok"
else
    echo "net.ipv4.conf.default.accept_source_route  >>> not ok"
fi

if [ "$(grep "net\.ipv4\.conf\.all\.accept_source_route" /etc/sysctl.conf /etc/sysctl.d/*)" == "net.ipv4.conf.all.accept_source_route= 0" ]; then
    echo "net.ipv4.conf.all.accept_source_route >>> ok"
else
    echo "net.ipv4.conf.all.accept_source_route >>> not ok"
fi

if [ "$( grep "net\.ipv4\.conf\.default\.accept_source_route" /etc/sysctl.conf /etc/sysctl.d/*)" == "net.ipv4.conf.default.accept_source_route= 0" ]; then
    echo "net.ipv4.conf.default.accept_source_route >>> ok"
else
    echo "net.ipv4.conf.default.accept_source_route >>> not ok"
fi

####21
echo "####21"
echo "####Ensure ICMP redirects are not accepted"
if [ "$( sysctl net.ipv4.conf.all.accept_redirects)" == "net.ipv4.conf.all.accept_redirects = 0" ]; then
    echo "net.ipv4.conf.all.accept_redirects >>> ok"
else
    echo "net.ipv4.conf.all.accept_redirects >>> not ok"
fi

if [ "$( sysctl net.ipv4.conf.default.accept_redirects)" == "net.ipv4.conf.default.accept_redirects = 0" ]; then
    echo "net.ipv4.conf.default.accept_redirects >>> ok"
else
    echo "net.ipv4.conf.default.accept_redirects >>> not ok"
fi

if [ "$( grep "net\.ipv4\.conf\.default\.accept_source_route" /etc/sysctl.conf /etc/sysctl.d/*)" == "net.ipv4.conf.all.accept_redirects= 0" ]; then
    echo "net.ipv4.conf.all.accept_redirects >>> ok"
else
    echo "net.ipv4.conf.all.accept_redirects >>> not ok"
fi

if [ "$( grep "net\.ipv4\.conf\.default\.accept_redirects" /etc/sysctl.conf /etc/sysctl.d/*)" == "net.ipv4.conf.default.accept_redirects= 0" ]; then
    echo "net.ipv4.conf.default.accept_redirects >>> ok"
else
    echo "net.ipv4.conf.default.accept_redirects >>> not ok"
fi

####22
echo "####22"
echo "####Ensure broadcast ICMP requests are ignored"
if [ "$(sysctl net.ipv4.icmp_echo_ignore_broadcasts)" == "net.ipv4.icmp_echo_ignore_broadcasts = 1" ]; then
    echo "net.ipv4.icmp_echo_ignore_broadcasts >>> ok"
else
    echo "net.ipv4.icmp_echo_ignore_broadcasts >>> not ok"
fi
if [ "$(grep -E -s "^\s*net\.ipv4\.icmp_echo_ignore_broadcasts\s*=\s*0" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf)" == "" ]; then
    echo "No value  returned >>> ok"
else
    echo "No value  returned >>> not ok"
fi


####23
echo "####23"
echo "####Ensure bogus ICMP responses are ignored"
if [ "$(sysctl net.ipv4.icmp_ignore_bogus_error_responses)" == "net.ipv4.icmp_ignore_bogus_error_responses = 1" ]; then
    echo "net.ipv4.icmp_ignore_bogus_error_responses >>> ok"
else
    echo "net.ipv4.icmp_ignore_bogus_error_responses >>> not ok"
fi

if [ "$(grep -E -s "^\s*net\.ipv4\.icmp_ignore_bogus_error_responses\s*=\s*0" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf)" == "" ]; then
    echo "No value  returned >>> ok"
else
    echo "No value  returned >>> not ok"
fi

####24
echo "####24"
echo "####Ensure TCP SYN Cookies is enabled"
if [ "$(sysctl net.ipv4.tcp_syncookies)" == "net.ipv4.tcp_syncookies = 1" ]; then
    echo "net.ipv4.tcp_syncookies >>> ok"
else
    echo "net.ipv4.tcp_syncookies >>> not ok"
fi

if [ "$(grep -E -r "^\s*net\.ipv4\.tcp_syncookies\s*=\s*[02]" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf )" == "" ]; then
    echo "No value  returned >>> ok"
else
    echo "No value  returned >>> not ok"
fi

####25
echo "####25"
echo "####Ensure SSH LogLevel is appropriate"
if [ "$(sshd -T | grep loglevel)" == "loglevel INFO" ]; then
    echo "loglevel >>> ok"
else
    echo "loglevel >>> not ok"
fi
####26
echo "####26"
echo "####Ensure SSH root login is disabled"
if [ "$(sshd -T | grep permitrootlogin)" == "PermitRootLogin no" ]; then
    echo "PermitRootLogin >>> ok"
else
    echo "PermitRootLogin >>> not ok"
fi

####27
echo "####27"
echo "####Ensure SSH PermitEmptyPasswords is disabled"
if [ "$(sshd -T | grep permitemptypasswords)" == "PermitEmptyPasswords no" ]; then
    echo "PermitEmptyPasswords >>> ok"
else
    echo "PermitEmptyPasswords >>> not ok"
fi

####28
echo "####28"
echo "####Ensure SSH access is limited"
if [ "$(sshd -T | grep -E '^\s*(allow|deny)(users|groups)\s+\S+')" != "" ]; then
    echo "ssh access  >>> ok"
else
    echo "ssh access >>> not ok"
fi


####29
echo "####29"
echo "####Ensure SSH Idle Timeout Interval is configured"
if [ "$(sshd -T | grep clientaliveinterval)" == "ClientAliveInterval 14400" ]; then
    echo "ClientAliveInterval >>> ok"
else
    echo "ClientAliveInterval >>> not ok"
fi

if [ "$(sshd -T | grep clientalivecountmax)" == "ClientAliveCountMax 0" ]; then
    echo "ClientAliveCountMax >>> ok"
else
    echo "ClientAliveCountMax >>> not ok"
fi

####30
echo "####30"
echo "####Ensure auditd is installed"
if [ "$(rpm -q audit audit-libs)" != "" ]; then
    echo "auditd is installed >>> ok"
else
    echo "auditd is installed >>> not ok"
fi

####31
echo "####31"
echo "####Ensure auditd service is enabled "
if [ "$(systemctl is-enabled auditd)" == "enabled" ]; then
    echo "auditd service is enabled >>> ok"
else
    echo "auditd service is enabled >>> not ok"
fi

####32
echo "####32"
echo "####Ensure max_log_file_action and num_logs options are configured "
if [ "$(grep max_log_file_action /etc/audit/auditd.conf)" == "max_log_file_action = ROTATE" ]; then
    echo "max_log_file_action >>> ok"
else
    echo "max_log_file_action >>> not ok"
fi

if [ "$(grep num_logs /etc/audit/auditd.conf)" == "num_logs = 5" ]; then
    echo "num_logs >>> ok"
else
    echo "num_logs >>> not ok"
fi

####33
echo "####33"
echo "####Ensure auditing for processes that start prior to auditd is enabled "
if [ "$(grep -E 'kernelopts=(\S+\s+)*audit=1\b' /boot/grub2/grubenv)" == "*adit= 1*" ]; then
    echo "auditd processes >>> ok"
else
    echo "auditd processes >>> not ok"
fi

####34
echo "####34"
echo "#### Ensure audit_backlog_limit is sufficient"
if [ "$(grep -E 'kernelopts=(\S+\s+)*audit_backlog_limit=\S+\b' /boot/grub2/grubenv)" == "*" ]; then
    echo "audit_backlog_limit >>> ok"
else
    echo "audit_backlog_limit >>> not ok"
fi

####35
echo "####35"
echo "#### Ensure audit log storage size is configured "
if [ "$(grep max_log_file grep max_log_file /etc/audit/auditd.conf)" == "max_log_file = 200" ]; then
    echo "max_log_file >>> ok"
else
    echo "max_log_file >>> not ok"
fi


####36
echo "####36"
echo "#### Ensure events that modify date and time information are collected"
if [ "$(auditctl -l | grep time-change)" == "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change" ]; then
    echo "time information  collected >>> ok"
else
    echo "time information collected >>> not ok"
fi

####37
echo "####37"
echo "#### Ensure events that modify user/group information are collected"
if [ "$( auditctl -l | grep identity)" == "-w /etc/group -p wa -k identity" ]; then
    echo "group information are collected >>> ok"
else
    echo "group information are collected >>> not ok"
fi
####37
echo "####37"
echo "#### Ensure events that modify user/group information are collected"
if [ "$( auditctl -l | grep identity)" == "-w /etc/group -p wa -k identity" ]; then
    echo "group information are collected >>> ok"
else
    echo "group information are collected >>> not ok"
fi

####38
echo "####38"
echo "#### Ensure events that modify the system's network environment are collected"
if [ "$( auditctl -l | grep system-locale)" == "-a always,exit -F arch=b64 -S sethostname,setdomainname -F key=system-locale" ]; then
    echo "system's network environment collected>>> ok"
else
    echo "system's network environment collected >>> not ok"
fi

####39
echo "####39"
echo "#### Ensure events that modify the system's Mandatory Access Controls are collected"
if [ "$( auditctl -l | grep MAC-policy)" == "-w /etc/selinux/ -p wa -k MAC-policy" ]; then
    echo "system's Mandatory Access Controls collected>>> ok"
else
    echo "system's Mandatory Access Controls collected >>> not ok"
fi

####40
echo "####40"
echo "#### Ensure login and logout events are collected"
if [ "$( auditctl -l | grep logins)" == "-w /var/log/faillog -p wa -k logins" ]; then
    echo "login and logout events collected>>> ok"
else
    echo "login and logout events collected >>> not ok"
fi


####41
echo "####41"
echo "#### Ensure session initiation information is collected"
if [ "$( auditctl -l | grep -E '(session|logins)')" == "-w /var/run/utmp -p wa -k session" ]; then
    echo "session initiation information collected>>> ok"
else
    echo "session initiation information collected >>> not ok"
fi


####41
echo "####41"
echo "#### Ensure session initiation information is collected"
if [ "$( auditctl -l | grep -E '(session|logins)')" == "-w /var/run/utmp -p wa -k session" ]; then
    echo "session initiation information collected>>> ok"
else
    echo "session initiation information collected >>> not ok"
fi

####42
echo "####42"
echo "#### Ensure discretionary access control permission modification events are collected"
if [ "$(auditctl -l | grep perm_mod)" == "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=-1 -k perm_mod" ]; then
    echo "access control permission modification events collected>>> ok"
else
    echo "access control permission modification events collected >>> not ok"
fi

####43
echo "####43"
echo "#### Ensure unsuccessful unauthorized file access attempts are collected"
if [ "$(auditctl -l | grep access)" == "-a always,exit -F arch=b64 -S open,truncate,ftruncate,creat,openat -F exit=-EACCES -F auid>=1000 -F auid!=-1 -F key=access" ]; then
    echo " unsuccessful unauthorized file access attempts are collected>>> ok"
else
    echo " unsuccessful unauthorized file access attempts are collected >>> not ok"
fi
####44
echo "####44"
echo "#### Ensure successful file system mounts are collected"
if [ "$(auditctl -l | grep mounts)" == "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=-1 -F key=mounts" ]; then
    echo " successful file system mounts are collected>>> ok"
else
    echo " successful file system mounts are collected >>> not ok"
fi
####45
echo "####45"
echo "#### Ensure file deletion events by users are collected"
if [ "$( auditctl -l | grep delete)" == "-a always,exit -F arch=b64 -S rename,unlink,unlinkat,renameat -F auid>=5100 -F auid!=-1 -F key=delete" ]; then
    echo "  file deletion events by users are collected >>> ok"
else
    echo "  file deletion events by users are collected >>> not ok"
fi

####46
echo "####46"
echo "#### Ensure changes to system administration scope (sudoers) is collected"
if [ "$(  auditctl -l | grep scope)" == "-w /etc/sudoers -p wa -k scope" ]; then
    echo "  system administration scope (sudoers) is collected >>> ok"
else
    echo "  system administration scope (sudoers) is collected >>> not ok"
fi
####47
echo "####47"
echo "#### Ensure system administrator actions (sudolog) are collected"
if [ "$( auditctl -l | grep actions )" == "-w /var/log/sudo.log -p wa -k actions" ]; then
    echo "  system administrator actions (sudolog) are collected >>> ok"
else
    echo "  system administrator actions (sudolog) are collected >>> not ok"
fi

####48
echo "####48"
echo "#### Ensure kernel module loading and unloading is collected"
if [ "$( auditctl -l | grep modules )" == "-w /sbin/insmod -p x -k modules" ]; then
    echo "  kernel module loading and unloading is collected >>> ok"
else
    echo "  kernel module loading and unloading is collected >>> not ok"
fi

####49
echo "####49"
echo "#### Ensure rsyslog is installed and enabled"
if [ "$( rpm -q rsyslog )" == "" ]; then
    echo " rsyslog is installed  >>>not ok"
else
    echo "  rsyslog is installed >>>  ok"
fi
if [ "$( systemctl is-enabled rsyslog )" == "enabled" ]; then
    echo " rsyslog is enabled  >>> ok"
else
    echo "  rsyslog is enabled >>> not ok"
fi
####50
echo "####50"
echo "#### Ensure rsyslog default file permissions configured"
if [ "$( grep ^\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf )" == "*0640*" ]; then
    echo "  rsyslog default file permissions configured >>> ok"
else
    echo "  rsyslog default file permissions configured >>> not ok"
fi

