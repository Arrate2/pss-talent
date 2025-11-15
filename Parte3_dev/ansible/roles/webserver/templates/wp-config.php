<?php
define('DB_NAME', '{{ wordpress_db_name | default('wordpress')}}');
define('DB_USER', '{{ wordpress_db_user | default('parte3_user')}}');
define('DB_PASSWORD', '{{ wordpress_db_password | default('parte3_pass')}}');
define('DB_HOST', '{{ db_host }}');
define('DB_CHARSET', 'utf8');
define('DB_COLLATE', '');
?>
