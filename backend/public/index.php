<?php

declare(strict_types=1);

ini_set('display_errors', '0');
require_once dirname(__DIR__) . '/src/bootstrap.php';

apply_http_headers();

if (request_method() === 'OPTIONS') {
    http_response_code(204);
    exit;
}
$method = request_method();
$path = request_path();

try {
    if ($method === 'GET' && $path === '/health') {
        api_health();
    }
    if ($method === 'GET' && $path === '/stores') {
        api_list_stores();
    }
    if ($method === 'GET' && preg_match('#^/stores/by-code/([^/]+)$#', $path, $matches)) {
        api_store_by_code($matches[1]);
    }
    if ($method === 'GET' && $path === '/products') {
        api_list_products();
    }
    if ($method === 'POST' && $path === '/products') {
        api_create_product();
    }
    if ($method === 'PUT' && preg_match('#^/products/([1-9][0-9]*)$#', $path, $matches)) {
        api_update_product((int) $matches[1]);
    }
    if ($method === 'GET' && $path === '/customers') {
        api_list_customers();
    }
    if ($method === 'POST' && $path === '/customers') {
        api_create_customer();
    }
    if ($method === 'PUT' && preg_match('#^/customers/([1-9][0-9]*)$#', $path, $matches)) {
        api_update_customer((int) $matches[1]);
    }
    if ($method === 'GET' && $path === '/orders') {
        api_list_orders();
    }
    if ($method === 'GET' && preg_match('#^/orders/([1-9][0-9]*)$#', $path, $matches)) {
        api_get_order((int) $matches[1]);
    }
    if ($method === 'POST' && $path === '/orders') {
        api_create_order();
    }
    if ($method === 'PATCH' && preg_match('#^/orders/([1-9][0-9]*)/status$#', $path, $matches)) {
        api_update_order_status((int) $matches[1]);
    }
    if ($method === 'GET' && $path === '/delivery-staff') {
        api_list_delivery_staff();
    }
    if ($method === 'POST' && $path === '/delivery-staff') {
        api_create_delivery_staff();
    }
    if ($method === 'POST' && $path === '/delivery-staff/login') {
        api_delivery_staff_login();
    }
    if ($method === 'GET' && $path === '/khata') {
        api_list_khata();
    }
    if ($method === 'POST' && $path === '/khata') {
        api_create_khata_credit();
    }
    if ($method === 'GET' && $path === '/reports') {
        api_reports();
    }

    throw new ApiException(404, 'NOT_FOUND', 'API route not found.');
} catch (ApiException $exception) {
    respond_error($exception->status, $exception->errorCode, $exception->getMessage(), $exception->details);
} catch (PDOException $exception) {
    $details = app_config()['debug'] ? array('database' => array($exception->getMessage())) : array();
    respond_error(500, 'DATABASE_ERROR', 'A database operation failed.', $details);
} catch (Throwable $exception) {
    $details = app_config()['debug'] ? array('exception' => array($exception->getMessage())) : array();
    respond_error(500, 'INTERNAL_ERROR', 'An unexpected server error occurred.', $details);
}
