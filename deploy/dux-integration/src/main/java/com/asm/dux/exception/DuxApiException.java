package com.asm.dux.exception;

/**
 * Represents a failure returned by the upstream DUX ERP API (HTTP 4xx / 5xx).
 * Thrown by infrastructure adapters; caught by GlobalExceptionHandler.
 */
public class DuxApiException extends RuntimeException {

    private final int upstreamStatus;

    public DuxApiException(String message, int upstreamStatus) {
        super(message);
        this.upstreamStatus = upstreamStatus;
    }

    public DuxApiException(String message, int upstreamStatus, Throwable cause) {
        super(message, cause);
        this.upstreamStatus = upstreamStatus;
    }

    public int getUpstreamStatus() {
        return upstreamStatus;
    }
}
