package com.asm.dux.infrastructure.dux;

import com.asm.dux.domain.port.TokenProvider;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

/**
 * Shared HTTP helper for all DUX ERP API calls.
 * Eliminates the 4× duplicated auth-header boilerplate (DRY + Single Responsibility).
 * All adapters delegate raw HTTP execution to this class.
 */
@Slf4j
@Component
public class DuxHttpClient {

    private final RestTemplate restTemplate;
    private final TokenProvider tokenProvider;

    public DuxHttpClient(RestTemplate restTemplate, TokenProvider tokenProvider) {
        this.restTemplate = restTemplate;
        this.tokenProvider = tokenProvider;
    }

    /**
     * Performs an authenticated GET request and returns the raw response body.
     */
    public String get(String url) {
        try {
            HttpHeaders headers = buildHeaders();
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.GET,
                    new HttpEntity<>(headers),
                    String.class);
            return response.getBody();
        } catch (HttpStatusCodeException e) {
            log.warn("DUX ERP GET {} returned HTTP {}: {}", url, e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("DUX ERP GET {} failed: {}", url, e.getMessage());
            return null;
        }
    }

    /**
     * Performs an authenticated POST request with a JSON string body.
     */
    public String post(String url, String jsonBody) {
        try {
            HttpHeaders headers = buildHeaders();
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.POST,
                    new HttpEntity<>(jsonBody, headers),
                    String.class);
            return response.getBody();
        } catch (HttpStatusCodeException e) {
            log.warn("DUX ERP POST {} returned HTTP {}: {}", url, e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("DUX ERP POST {} failed: {}", url, e.getMessage());
            return null;
        }
    }

    /**
     * Performs an authenticated POST request with a typed body.
     */
    public <T> String post(String url, T body) {
        try {
            HttpHeaders headers = buildHeaders();
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.POST,
                    new HttpEntity<>(body, headers),
                    String.class);
            return response.getBody();
        } catch (HttpStatusCodeException e) {
            log.warn("DUX ERP POST {} returned HTTP {}: {}", url, e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("DUX ERP POST {} failed: {}", url, e.getMessage());
            return null;
        }
    }

    /**
     * Performs an authenticated DELETE request and returns the raw response body.
     */
    public String delete(String url) {
        try {
            HttpHeaders headers = buildHeaders();
            ResponseEntity<String> response = restTemplate.exchange(
                    url, HttpMethod.DELETE,
                    new HttpEntity<>(headers),
                    String.class);
            return response.getBody();
        } catch (HttpStatusCodeException e) {
            log.warn("DUX ERP DELETE {} returned HTTP {}: {}", url, e.getStatusCode(), e.getResponseBodyAsString());
            return null;
        } catch (Exception e) {
            log.error("DUX ERP DELETE {} failed: {}", url, e.getMessage());
            return null;
        }
    }

    private HttpHeaders buildHeaders() {
        String token = tokenProvider.getAccessToken();
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.add("token", token);
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }
}
