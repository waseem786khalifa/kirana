<?php

declare(strict_types=1);

/**
 * Tiny dependency-free .env loader for local XAMPP development.
 * Existing process environment variables always win.
 */
function load_env_file(string $path): void
{
    if (!is_file($path) || !is_readable($path)) {
        return;
    }

    $lines = file($path, FILE_IGNORE_NEW_LINES);
    if ($lines === false) {
        return;
    }

    foreach ($lines as $line) {
        $line = trim($line);
        if ($line === '' || $line[0] === '#') {
            continue;
        }

        if (strpos($line, 'export ') === 0) {
            $line = trim(substr($line, 7));
        }

        $separator = strpos($line, '=');
        if ($separator === false) {
            continue;
        }

        $name = trim(substr($line, 0, $separator));
        $value = trim(substr($line, $separator + 1));
        if (!preg_match('/^[A-Z_][A-Z0-9_]*$/i', $name)) {
            continue;
        }

        if (getenv($name) !== false) {
            continue;
        }

        $length = strlen($value);
        if ($length >= 2) {
            $first = $value[0];
            $last = $value[$length - 1];
            if (($first === '"' && $last === '"') || ($first === "'" && $last === "'")) {
                $value = substr($value, 1, -1);
            }
        }

        putenv($name . '=' . $value);
        $_ENV[$name] = $value;
    }
}
function env_value(string $name, $default = null)
{
    $value = getenv($name);
    return $value === false ? $default : $value;
}

function env_bool(string $name, bool $default): bool
{
    $value = env_value($name);
    if ($value === null || $value === '') {
        return $default;
    }

    $parsed = filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    return $parsed === null ? $default : $parsed;
}

function app_config(): array
{
    static $config = null;
    if ($config !== null) {
        return $config;
    }

    $origins = array_values(array_filter(array_map('trim', explode(',', (string) env_value(
        'CORS_ALLOWED_ORIGINS',
        'http://localhost,http://127.0.0.1,http://localhost:3000,http://127.0.0.1:3000,http://localhost:5173,http://127.0.0.1:5173'
    )))));

    $config = array(
        'app_env' => (string) env_value('APP_ENV', 'local'),
        'debug' => env_bool('APP_DEBUG', true),
        'timezone' => (string) env_value('APP_TIMEZONE', 'Asia/Kolkata'),
        'cors_allowed_origins' => $origins,
        'allow_localhost_any_port' => env_bool('CORS_ALLOW_LOCALHOST_ANY_PORT', true),
        'token_ttl_seconds' => max(300, (int) env_value('AUTH_TOKEN_TTL_SECONDS', 43200)),
        'db' => array(
            'host' => (string) env_value('DB_HOST', '127.0.0.1'),
            'port' => (int) env_value('DB_PORT', 3306),
            'name' => (string) env_value('DB_DATABASE', 'kirana_saarthi'),
            'user' => (string) env_value('DB_USERNAME', 'root'),
            'password' => (string) env_value('DB_PASSWORD', ''),
        ),
    );

    date_default_timezone_set($config['timezone']);
    return $config;
}
