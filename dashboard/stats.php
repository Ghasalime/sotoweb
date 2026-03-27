<?php
header('Content-Type: application/json');

// Get Hostname
$hostname = gethostname();

// Get Uptime
$uptime = shell_exec('uptime -p');

// Check Service Status
$services = [
    'nginx' => shell_exec('systemctl is-active nginx'),
    'mariadb' => shell_exec('systemctl is-active mariadb'),
    'php-fpm' => shell_exec('systemctl is-active php' . shell_exec('php -r "echo PHP_MAJOR_VERSION.\'.\'.PHP_MINOR_VERSION;"') . '-fpm')
];

// Clean service status
foreach ($services as $key => $val) {
    $services[$key] = trim($val);
}

// Get CPU Load
$load = sys_getloadavg();

// Get Memory Info (Total, Used) in MB
$free_output = shell_exec('free -m');
preg_match('/Mem:\s+(\d+)\s+(\d+)/', $free_output, $mem_matches);
$mem = [$mem_matches[1], $mem_matches[2]];

// Get Disk Info (Total, Used, Percentage) for root
$df_output = shell_exec('df -h /');
$df_lines = explode("\n", trim($df_output));
$df_data = preg_split('/\s+/', $df_lines[1]);
$disk = [$df_data[1], $df_data[2], $df_data[4]];

echo json_encode([
    'hostname' => $hostname,
    'uptime' => trim($uptime),
    'services' => $services,
    'load' => $load,
    'mem' => $mem,
    'disk' => $disk
], JSON_PRETTY_PRINT);
?>
