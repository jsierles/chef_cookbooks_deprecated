default.keepalived[:config_path] = "/etc/keepalived/keepalived.conf"
default.keepalived[:notification_email] = "sysadmin@example.com"
default.keepalived[:email_from] = "keepalived@example.com"
default.keepalived[:smtp_host] = "1.2.3.4"
default.keepalived[:smtp_timeout] = 30
default.keepalived[:lvs_id] = node[:hostname]
default.keepalived[:router_id] = node[:hostname]
default.keepalived[:vrrp_instances] = []
