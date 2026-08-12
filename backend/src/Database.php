<?php

declare(strict_types=1);

function db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $appConfig = app_config();
    $config = $appConfig['db'];
    $dsn = sprintf(
        'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
        $config['host'],
        $config['port'],
        $config['name']
    );

    $pdo = new PDO($dsn, $config['user'], $config['password'], array(
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
        PDO::ATTR_STRINGIFY_FETCHES => false,
    ));

    $pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
    $timezone = new DateTimeZone($appConfig['timezone']);
    $utcOffset = (new DateTimeImmutable('now', $timezone))->format('P');
    $pdo->exec('SET time_zone = ' . $pdo->quote($utcOffset));
    return $pdo;
}
/**
 * Run a callback atomically and roll back on every Throwable.
 */
function in_transaction(callable $callback)
{
    $pdo = db();
    $startedHere = !$pdo->inTransaction();
    if ($startedHere) {
        $pdo->beginTransaction();
    }

    try {
        $result = $callback($pdo);
        if ($startedHere && $pdo->inTransaction()) {
            $pdo->commit();
        }
        return $result;
    } catch (Throwable $exception) {
        if ($startedHere && $pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $exception;
    }
}
