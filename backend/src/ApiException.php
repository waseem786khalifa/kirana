<?php

declare(strict_types=1);

final class ApiException extends RuntimeException
{
    /** @var int */
    public $status;

    /** @var string */
    public $errorCode;

    /** @var array */
    public $details;

    public function __construct(int $status, string $errorCode, string $message, array $details = array())
    {
        parent::__construct($message);
        $this->status = $status;
        $this->errorCode = $errorCode;
        $this->details = $details;
    }
}
