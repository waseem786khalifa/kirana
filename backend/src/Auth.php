<?php

declare(strict_types=1);

function admin_user_resource(array $row): array
{
    return array(
        'id' => (int) $row['id'],
        'email' => (string) $row['email'],
        'name' => (string) $row['name'],
        'role' => (string) $row['role'],
        'is_active' => (bool) $row['is_active'],
        'last_login_at' => $row['last_login_at'],
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at'],
    );
}

function admin_json_value(?array $value): ?string
{
    if ($value === null) {
        return null;
    }
    $json = json_encode($value, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRESERVE_ZERO_FRACTION);
    return $json === false ? null : $json;
}

function admin_client_ip(): string
{
    return isset($_SERVER['REMOTE_ADDR'])
        ? substr(trim((string) $_SERVER['REMOTE_ADDR']), 0, 45)
        : '';
}

function admin_audit(
    PDO $pdo,
    ?int $adminUserId,
    string $action,
    string $resourceType,
    ?string $resourceId = null,
    ?int $storeId = null,
    ?array $before = null,
    ?array $after = null,
    ?array $metadata = null
): void {
    $ip = admin_client_ip();
    $userAgent = isset($_SERVER['HTTP_USER_AGENT'])
        ? substr(trim((string) $_SERVER['HTTP_USER_AGENT']), 0, 500)
        : '';
    $statement = $pdo->prepare(
        'INSERT INTO admin_audit_logs '
        . '(admin_user_id, action, resource_type, resource_id, store_id, request_id, ip_address, user_agent, before_json, after_json, metadata_json) '
        . 'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    $statement->execute(array(
        $adminUserId,
        substr($action, 0, 100),
        substr($resourceType, 0, 80),
        $resourceId === null ? null : substr($resourceId, 0, 100),
        $storeId,
        request_id(),
        $ip,
        $userAgent,
        admin_json_value($before),
        admin_json_value($after),
        admin_json_value($metadata),
    ));
}

function bearer_token_from_request(): string
{
    $authorization = isset($_SERVER['HTTP_AUTHORIZATION'])
        ? trim((string) $_SERVER['HTTP_AUTHORIZATION'])
        : (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])
            ? trim((string) $_SERVER['REDIRECT_HTTP_AUTHORIZATION'])
            : '');
    if (!preg_match('/^Bearer\s+([A-Fa-f0-9]{64})$/', $authorization, $matches)) {
        throw new ApiException(401, 'UNAUTHORIZED', 'A valid administrator bearer token is required.');
    }
    return $matches[1];
}

/**
 * Return the authenticated super-admin and the current hashed session token.
 * Every /admin route except login calls this helper before dispatch.
 */
function require_super_admin(): array
{
    $rawToken = bearer_token_from_request();
    $tokenHash = hash('sha256', $rawToken);
    $statement = db()->prepare(
        'SELECT au.*, at.id AS admin_token_id '
        . 'FROM admin_tokens at JOIN admin_users au ON au.id = at.admin_user_id '
        . 'WHERE at.token_hash = ? AND at.revoked_at IS NULL AND at.expires_at > NOW() '
        . 'AND au.is_active = 1 LIMIT 1'
    );
    $statement->execute(array($tokenHash));
    $user = $statement->fetch();
    if (!$user) {
        throw new ApiException(401, 'UNAUTHORIZED', 'Administrator session is invalid or expired.');
    }
    if ((string) $user['role'] !== 'SUPER_ADMIN') {
        throw new ApiException(403, 'FORBIDDEN', 'Super-admin permission is required.');
    }
    db()->prepare('UPDATE admin_tokens SET last_used_at = NOW() WHERE id = ?')
        ->execute(array((int) $user['admin_token_id']));
    return array('user' => $user, 'token_hash' => $tokenHash);
}

function api_admin_login(): void
{
    $body = json_body();
    reject_unknown_fields($body, array('email', 'password'));
    $email = strtolower(required_string($body, 'email', 254, 3));
    if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
        validation_error(array('email' => array('A valid email address is required.')));
    }
    $password = required_string($body, 'password', 512, 1);

    $statement = db()->prepare('SELECT * FROM admin_users WHERE email = ? LIMIT 1');
    $statement->execute(array($email));
    $user = $statement->fetch();
    // Always perform a bcrypt verification so an unknown email has a comparable response cost.
    $candidateHash = $user
        ? (string) $user['password_hash']
        : '$2y$10$jCrZ8.ZgfJ33RX3n9BdHT.7XTqEi8WY/cv8GuptolRBNfeD7qcrMm';
    $passwordMatches = password_verify($password, $candidateHash);
    if (!$user) {
        usleep(125000);
        throw new ApiException(401, 'UNAUTHORIZED', 'Invalid email or password.');
    }

    $config = app_config();
    $maxAttempts = (int) $config['admin_max_login_attempts'];
    $lockSeconds = (int) $config['admin_lock_seconds'];
    $tokenTtl = (int) $config['admin_token_ttl_seconds'];
    $ip = admin_client_ip();
    $attemptKey = hash('sha256', $email . "\0" . $ip);
    $emailHash = hash('sha256', $email);

    $result = in_transaction(function (PDO $pdo) use (
        $user,
        $passwordMatches,
        $attemptKey,
        $emailHash,
        $ip,
        $maxAttempts,
        $lockSeconds,
        $tokenTtl
    ): array {
        $pdo->prepare(
            'DELETE FROM admin_login_attempts WHERE last_failed_at < DATE_SUB(NOW(), INTERVAL 1 DAY) '
            . 'AND (locked_until IS NULL OR locked_until < NOW())'
        )->execute();
        $pdo->prepare(
            'INSERT IGNORE INTO admin_login_attempts (attempt_key, email_hash, ip_address) VALUES (?, ?, ?)'
        )->execute(array($attemptKey, $emailHash, $ip));
        $statement = $pdo->prepare(
            'SELECT *, (locked_until IS NOT NULL AND locked_until > NOW()) AS is_locked, '
            . '(last_failed_at IS NOT NULL AND last_failed_at < DATE_SUB(NOW(), INTERVAL '
            . $lockSeconds . ' SECOND)) AS is_stale FROM admin_login_attempts WHERE attempt_key = ? FOR UPDATE'
        );
        $statement->execute(array($attemptKey));
        $bucket = $statement->fetch();
        if ((bool) $bucket['is_locked']) {
            return array('status' => 'blocked');
        }
        $attempts = (bool) $bucket['is_stale'] ? 0 : (int) $bucket['failed_attempts'];
        $valid = (bool) $user['is_active']
            && (string) $user['role'] === 'SUPER_ADMIN'
            && $passwordMatches;
        if (!$valid) {
            $attempts++;
            $locked = $attempts >= $maxAttempts;
            $lockedExpression = $locked
                ? 'DATE_ADD(NOW(), INTERVAL ' . $lockSeconds . ' SECOND)'
                : 'NULL';
            $pdo->prepare(
                'UPDATE admin_login_attempts SET failed_attempts = ?, locked_until = '
                . $lockedExpression . ', last_failed_at = NOW() WHERE attempt_key = ?'
            )->execute(array($attempts, $attemptKey));
            if ($attempts === 1 || $locked) {
                admin_audit(
                    $pdo,
                    (int) $user['id'],
                    $locked ? 'auth.login_throttled' : 'auth.login_failed',
                    'admin_session',
                    null,
                    null,
                    null,
                    null,
                    array('attempts_in_window' => $attempts)
                );
            }
            return array('status' => $locked ? 'blocked' : 'invalid');
        }

        $rawToken = bin2hex(random_bytes(32));
        $tokenHash = hash('sha256', $rawToken);
        $expiresAt = (string) $pdo->query(
            'SELECT DATE_ADD(NOW(), INTERVAL ' . $tokenTtl . ' SECOND)'
        )->fetchColumn();
        $pdo->prepare(
            'DELETE FROM admin_tokens WHERE expires_at <= NOW() OR (revoked_at IS NOT NULL AND revoked_at < DATE_SUB(NOW(), INTERVAL 7 DAY))'
        )->execute();
        $pdo->prepare(
            'UPDATE admin_users SET failed_login_attempts = 0, locked_until = NULL, last_login_at = NOW() WHERE id = ?'
        )->execute(array((int) $user['id']));
        $pdo->prepare('DELETE FROM admin_login_attempts WHERE attempt_key = ?')->execute(array($attemptKey));
        $pdo->prepare(
            'INSERT INTO admin_tokens (admin_user_id, token_hash, expires_at, last_used_at) VALUES (?, ?, ?, NOW())'
        )->execute(array((int) $user['id'], $tokenHash, $expiresAt));
        admin_audit(
            $pdo,
            (int) $user['id'],
            'auth.login_succeeded',
            'admin_session',
            (string) $pdo->lastInsertId()
        );
        $statement = $pdo->prepare('SELECT * FROM admin_users WHERE id = ?');
        $statement->execute(array((int) $user['id']));
        return array(
            'status' => 'success',
            'raw_token' => $rawToken,
            'expires_at' => $expiresAt,
            'user' => $statement->fetch(),
        );
    });

    if ($result['status'] !== 'success') {
        usleep(125000);
        if ($result['status'] === 'blocked') {
            throw new ApiException(429, 'TOO_MANY_ATTEMPTS', 'Too many login attempts from this source. Try again later.');
        }
        throw new ApiException(401, 'UNAUTHORIZED', 'Invalid email or password.');
    }

    respond_data(array(
        'token' => $result['raw_token'],
        'token_type' => 'Bearer',
        'expires_at' => date(DATE_ATOM, strtotime($result['expires_at'])),
        'admin' => admin_user_resource($result['user']),
    ));
}

function api_admin_me(array $adminContext): void
{
    respond_data(admin_user_resource($adminContext['user']));
}

function api_admin_logout(array $adminContext): void
{
    in_transaction(function (PDO $pdo) use ($adminContext): void {
        $statement = $pdo->prepare(
            'UPDATE admin_tokens SET revoked_at = NOW() WHERE token_hash = ? AND revoked_at IS NULL'
        );
        $statement->execute(array($adminContext['token_hash']));
        admin_audit(
            $pdo,
            (int) $adminContext['user']['id'],
            'auth.logout',
            'admin_session',
            (string) $adminContext['user']['admin_token_id']
        );
    });
    respond_data(array('logged_out' => true));
}
