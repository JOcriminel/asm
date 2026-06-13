package com.asm.dux.exception;

import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.client.RestClientException;

/**
 * Centralized exception-to-HTTP-response mapping (Open/Closed principle).
 * Controllers no longer need try/catch blocks — adding new exception types
 * only requires adding a new handler method here.
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final HttpHeaders JSON_HEADERS;

    static {
        JSON_HEADERS = new HttpHeaders();
        JSON_HEADERS.setContentType(MediaType.APPLICATION_JSON);
    }

    /** Upstream DUX ERP returned a non-2xx response. */
    @ExceptionHandler(DuxApiException.class)
    public ResponseEntity<String> handleDuxApiException(DuxApiException ex) {
        log.error("DUX API error (upstream {}): {}", ex.getUpstreamStatus(), ex.getMessage());
        return ResponseEntity
                .status(502)
                .headers(JSON_HEADERS)
                .body(errorJson("DUX API call failed", ex.getMessage()));
    }

    /** Internal adapter / serialization failure. */
    @ExceptionHandler(GatewayException.class)
    public ResponseEntity<String> handleGatewayException(GatewayException ex) {
        log.error("Gateway error: {}", ex.getMessage(), ex);
        return ResponseEntity
                .status(500)
                .headers(JSON_HEADERS)
                .body(errorJson("Internal gateway error", ex.getMessage()));
    }

    /** Low-level Spring RestTemplate HTTP failure. */
    @ExceptionHandler(RestClientException.class)
    public ResponseEntity<String> handleRestClientException(RestClientException ex) {
        log.error("RestClient error: {}", ex.getMessage());
        return ResponseEntity
                .status(502)
                .headers(JSON_HEADERS)
                .body(errorJson("DUX API call failed", ex.getMessage()));
    }

    /** Catch-all for any unhandled runtime exception. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<String> handleGenericException(Exception ex) {
        log.error("Unexpected error: {}", ex.getMessage(), ex);
        return ResponseEntity
                .status(500)
                .headers(JSON_HEADERS)
                .body(errorJson("Internal server error", ex.getMessage()));
    }

    private String errorJson(String error, String detail) {
        String safeDetail = detail != null ? detail.replace("\"", "'") : "unknown";
        return "{\"error\": \"%s\", \"detail\": \"%s\"}".formatted(error, safeDetail);
    }
}
