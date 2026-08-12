<?php

declare(strict_types=1);

require_once __DIR__ . '/Config.php';
load_env_file(dirname(__DIR__) . '/.env');
app_config();

require_once __DIR__ . '/ApiException.php';
require_once __DIR__ . '/Database.php';
require_once __DIR__ . '/Http.php';
require_once __DIR__ . '/Validation.php';
require_once __DIR__ . '/Auth.php';
require_once __DIR__ . '/Api.php';
require_once __DIR__ . '/AdminApi.php';
