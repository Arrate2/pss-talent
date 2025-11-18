<?php
define('DB_NAME', '{{ wordpress_db_name | default('wordpress')}}');
define('DB_USER', '{{ wordpress_db_user | default('pf_user')}}');
define('DB_PASSWORD', '{{ wordpress_db_password | default('pf_pass')}}');
define('DB_HOST', '{{ db_host }}:{{db_port}}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
?>
