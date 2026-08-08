<?php

declare(strict_types=1);

function validation_error(array $details): void
{
    throw new ApiException(422, 'VALIDATION_ERROR', 'One or more fields are invalid.', $details);
}

function reject_unknown_fields(array $input, array $allowed): void
{
    $unknown = array_values(array_diff(array_keys($input), $allowed));
    if ($unknown !== array()) {
        validation_error(array('_schema' => array('Unknown fields: ' . implode(', ', $unknown) . '.')));
    }
}

function required_string(array $input, string $field, int $maxLength, int $minLength = 1): string
{
    if (!array_key_exists($field, $input) || !is_string($input[$field])) {
        validation_error(array($field => array('A string value is required.')));
    }
    $value = trim($input[$field]);
    $length = function_exists('mb_strlen') ? mb_strlen($value) : strlen($value);
    if ($length < $minLength || $length > $maxLength) {
        validation_error(array($field => array(sprintf('Length must be between %d and %d characters.', $minLength, $maxLength))));
    }
    return $value;
}

function optional_string(array $input, string $field, int $maxLength, ?string $default = null): ?string
{
    if (!array_key_exists($field, $input) || $input[$field] === null) {
        return $default;
    }
    if (!is_string($input[$field])) {
        validation_error(array($field => array('Must be a string.')));
    }
    $value = trim($input[$field]);
    $length = function_exists('mb_strlen') ? mb_strlen($value) : strlen($value);
    if ($length > $maxLength) {
        validation_error(array($field => array(sprintf('Must not exceed %d characters.', $maxLength))));
    }
    return $value;
}

function required_int(array $input, string $field, int $min = 1, ?int $max = null): int
{
    if (!array_key_exists($field, $input)) {
        validation_error(array($field => array('An integer value is required.')));
    }
    $value = filter_var($input[$field], FILTER_VALIDATE_INT);
    if ($value === false || $value < $min || ($max !== null && $value > $max)) {
        validation_error(array($field => array('Must be an integer in the allowed range.')));
    }
    return (int) $value;
}

function optional_int(array $input, string $field, int $default, int $min = 0, ?int $max = null): int
{
    if (!array_key_exists($field, $input)) {
        return $default;
    }
    return required_int($input, $field, $min, $max);
}

function optional_bool(array $input, string $field, bool $default): bool
{
    if (!array_key_exists($field, $input)) {
        return $default;
    }
    if (is_bool($input[$field])) {
        return $input[$field];
    }
    if ($input[$field] === 0 || $input[$field] === 1 || $input[$field] === '0' || $input[$field] === '1') {
        return (bool) $input[$field];
    }
    validation_error(array($field => array('Must be a boolean.')));
}

function required_money(array $input, string $field, float $min = 0.01, ?float $max = null): float
{
    if (!array_key_exists($field, $input) || !is_numeric($input[$field])) {
        validation_error(array($field => array('A numeric amount is required.')));
    }
    $value = round((float) $input[$field], 2);
    if (!is_finite($value) || $value < $min || ($max !== null && $value > $max)) {
        validation_error(array($field => array('Amount is outside the allowed range.')));
    }
    return $value;
}

function optional_money(array $input, string $field, float $default, float $min = 0.0, ?float $max = null): float
{
    if (!array_key_exists($field, $input)) {
        return $default;
    }
    return required_money($input, $field, $min, $max);
}

function enum_value(array $input, string $field, array $allowed): string
{
    $value = required_string($input, $field, 40);
    $value = strtoupper($value);
    if (!in_array($value, $allowed, true)) {
        validation_error(array($field => array('Allowed values: ' . implode(', ', $allowed) . '.')));
    }
    return $value;
}

function validate_mobile(string $mobile, string $field = 'mobile'): string
{
    $digits = preg_replace('/\D+/', '', $mobile);
    if ($digits === null || strlen($digits) < 10 || strlen($digits) > 15) {
        validation_error(array($field => array('Must contain 10 to 15 digits.')));
    }
    return $digits;
}

function validate_pincode(string $pincode, string $field = 'pincode'): string
{
    if (!preg_match('/^[0-9]{6}$/', $pincode)) {
        validation_error(array($field => array('Must be a 6-digit Indian pincode.')));
    }
    return $pincode;
}

function validate_address(array $input, string $prefix = 'address'): array
{
    $label = optional_string($input, 'label', 20, 'Home');
    if (!in_array($label, array('Home', 'Office', 'Other'), true)) {
        validation_error(array($prefix . '.label' => array('Allowed values: Home, Office, Other.')));
    }

    return array(
        'label' => $label,
        'address_line' => required_string($input, 'address_line', 500),
        'landmark' => optional_string($input, 'landmark', 255, ''),
        'pincode' => validate_pincode(required_string($input, 'pincode', 6, 6), $prefix . '.pincode'),
    );
}
