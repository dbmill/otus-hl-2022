<?php
$conn = new PDO("mysql:host=192.168.56.20", "dbuser", "pass123");

echo "Front-end: ", $_SERVER['FE_SERVER'], "\n";
echo "Back-end: ", gethostname(), "\n";
$res = $conn->query("SELECT @@version, @@pseudo_thread_id");
$row = $res->fetch(PDO::FETCH_NUM);
echo "MySQL version: ", $row[0], "\n";
echo "Connection id: ", $row[1], "\n";
