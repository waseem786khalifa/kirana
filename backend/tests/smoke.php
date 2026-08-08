<?php

declare(strict_types=1);

$baseUrl = rtrim((string) (getenv('KIRANA_API_URL') ?: 'http://127.0.0.1:8080'), '/');

function request_json(string $url, string $method = 'GET', ?array $body = null): array
{
    $headers = array('Accept: application/json');
    $options = array('method' => $method, 'ignore_errors' => true, 'timeout' => 5);
    if ($body !== null) {
        $headers[] = 'Content-Type: application/json';
        $options['content'] = json_encode($body);
    }
    $options['header'] = implode("\r\n", $headers);
    $context = stream_context_create(array('http' => $options));
    $raw = file_get_contents($url, false, $context);
    if ($raw === false) {
        throw new RuntimeException('Request failed: ' . $url);
    }
    $status = 0;
    if (isset($http_response_header[0]) && preg_match('/\s([0-9]{3})\s/', $http_response_header[0], $matches)) {
        $status = (int) $matches[1];
    }
    $json = json_decode($raw, true);
    if (!is_array($json)) {
        throw new RuntimeException('Non-JSON response from ' . $url . ': ' . $raw);
    }
    return array('status' => $status, 'json' => $json);
}

function check(bool $condition, string $message): void
{
    if (!$condition) {
        throw new RuntimeException('FAIL: ' . $message);
    }
    echo 'PASS: ' . $message . PHP_EOL;
}

$health = request_json($baseUrl . '/health');
check($health['status'] === 200, 'health returns 200');
check($health['json']['data']['database'] === 'ok', 'database connection is healthy');

$stores = request_json($baseUrl . '/stores?limit=2');
check($stores['status'] === 200 && isset($stores['json']['data'][0]['delivery_settings']), 'stores use the documented envelope');

$products = request_json($baseUrl . '/products?store_id=1&limit=2');
check($products['status'] === 200 && isset($products['json']['data'][0]['selling_price']), 'products are snake_case');

$orders = request_json($baseUrl . '/orders?store_id=1&limit=1');
check($orders['status'] === 200 && isset($orders['json']['data'][0]['items']), 'orders include item snapshots');

$badLogin = request_json($baseUrl . '/delivery-staff/login', 'POST', array(
    'store_id' => 1,
    'mobile' => '9828877665',
    'pin' => '0000',
));
check($badLogin['status'] === 401 && !isset($badLogin['json']['data']), 'invalid rider PIN is rejected without credential exposure');

echo 'Smoke checks completed.' . PHP_EOL;
