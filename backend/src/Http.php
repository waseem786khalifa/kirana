<?php

declare(strict_types=1);

function request_id(): string
{
    static $id = null;
    if ($id === null) {
        try {
            $id = bin2hex(random_bytes(8));
        } catch (Throwable $exception) {
            $id = uniqid('req_', true);
        }
    }
    return $id;
}
function apply_http_headers(): void
{
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('Referrer-Policy: no-referrer');
    header('Cache-Control: no-store');
    header('X-Request-Id: ' . request_id());

    $origin = isset($_SERVER['HTTP_ORIGIN']) ? trim((string) $_SERVER['HTTP_ORIGIN']) : '';
    if ($origin !== '' && cors_origin_allowed($origin)) {
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Vary: Origin');
        header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization, Idempotency-Key, X-Request-Id');
        header('Access-Control-Max-Age: 600');
    }
}

function cors_origin_allowed(string $origin): bool
{
    $config = app_config();
    if (in_array($origin, $config['cors_allowed_origins'], true)) {
        return true;
    }

    if (!$config['allow_localhost_any_port']) {
        return false;
    }

    return preg_match('#^https?://(?:localhost|127\.0\.0\.1)(?::\d{1,5})?$#i', $origin) === 1;
}

function respond_data($data, int $status = 200, ?array $meta = null): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    $payload = array('data' => $data);
    if ($meta !== null) {
        $payload['meta'] = $meta;
    }
    echo json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRESERVE_ZERO_FRACTION);
    exit;
}

function respond_error(int $status, string $code, string $message, array $details = array()): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    $error = array(
        'code' => $code,
        'message' => $message,
        'request_id' => request_id(),
    );
    if ($details !== array()) {
        $error['details'] = $details;
    }
    echo json_encode(array('error' => $error), JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    exit;
}

function request_method(): string
{
    return strtoupper(isset($_SERVER['REQUEST_METHOD']) ? (string) $_SERVER['REQUEST_METHOD'] : 'GET');
}

function request_path(): string
{
    $uri = isset($_SERVER['REQUEST_URI']) ? (string) $_SERVER['REQUEST_URI'] : '/';
    $path = rawurldecode((string) parse_url($uri, PHP_URL_PATH));
    $scriptName = isset($_SERVER['SCRIPT_NAME']) ? str_replace('\\', '/', (string) $_SERVER['SCRIPT_NAME']) : '';

    if ($scriptName !== '' && strpos($path, $scriptName) === 0) {
        $path = substr($path, strlen($scriptName));
    } else {
        $base = rtrim(str_replace('\\', '/', dirname($scriptName)), '/.');
        if ($base !== '' && $base !== '/' && strpos($path, $base . '/') === 0) {
            $path = substr($path, strlen($base));
        }
    }

    $path = '/' . ltrim($path, '/');
    if ($path === '/api') {
        return '/';
    }
    if (strpos($path, '/api/') === 0) {
        $path = substr($path, 4);
    }
    return rtrim($path, '/') ?: '/';
}

function json_body(): array
{
    $contentType = isset($_SERVER['CONTENT_TYPE']) ? strtolower((string) $_SERVER['CONTENT_TYPE']) : '';
    if ($contentType !== '' && strpos($contentType, 'application/json') !== 0) {
        throw new ApiException(415, 'UNSUPPORTED_MEDIA_TYPE', 'Content-Type must be application/json.');
    }

    $contentLength = isset($_SERVER['CONTENT_LENGTH']) ? (int) $_SERVER['CONTENT_LENGTH'] : 0;
    if ($contentLength > 1048576) {
        throw new ApiException(413, 'PAYLOAD_TOO_LARGE', 'JSON request body must be 1 MB or smaller.');
    }

    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        throw new ApiException(400, 'INVALID_JSON', 'A JSON object request body is required.');
    }

    $decoded = json_decode($raw, true);
    if (!is_array($decoded) || json_last_error() !== JSON_ERROR_NONE || array_values($decoded) === $decoded) {
        throw new ApiException(400, 'INVALID_JSON', 'Request body must be a valid JSON object.');
    }
    return $decoded;
}

function query_int(string $name, ?int $default = null, int $min = 1, ?int $max = null): ?int
{
    if (!isset($_GET[$name]) || $_GET[$name] === '') {
        return $default;
    }
    $value = filter_var($_GET[$name], FILTER_VALIDATE_INT);
    if ($value === false || $value < $min || ($max !== null && $value > $max)) {
        throw new ApiException(422, 'VALIDATION_ERROR', 'Invalid query parameters.', array(
            $name => array('Must be an integer in the allowed range.'),
        ));
    }
    return (int) $value;
}

function pagination(): array
{
    return array(
        'limit' => query_int('limit', 100, 1, 200),
        'offset' => query_int('offset', 0, 0, 1000000),
    );
}
