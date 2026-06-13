package com.asm.dux.exception;

/**
 * Represents a general internal gateway failure (e.g., serialization error,
 * unexpected state). Distinct from DuxApiException (which is an upstream HTTP failure).
 */
public class GatewayException extends RuntimeException {

    public GatewayException(String message) {
        super(message);
    }

    public GatewayException(String message, Throwable cause) {
        super(message, cause);
    }
}
