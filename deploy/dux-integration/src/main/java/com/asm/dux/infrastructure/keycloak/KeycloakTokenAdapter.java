package com.asm.dux.infrastructure.keycloak;

import com.asm.dux.domain.port.TokenProvider;
import com.asm.dux.dto.TokenResponse;
import com.asm.dux.exception.DuxApiException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

/**
 * Infrastructure adapter: obtains an access token from Keycloak using
 * the client_credentials grant. Implements the {@link TokenProvider} domain port.
 */
@Slf4j
@Component
public class KeycloakTokenAdapter implements TokenProvider {

    private final RestTemplate restTemplate;

    @Value("${dux.token-url}")
    private String tokenUrl;

    @Value("${dux.client-id}")
    private String clientId;

    @Value("${dux.client-secret}")
    private String clientSecret;

    private String cachedToken;
    private long expiryTimeMillis;
    private final Object lock = new Object();

    public KeycloakTokenAdapter(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @Override
    public String getAccessToken() {
        synchronized (lock) {
            if (cachedToken != null && System.currentTimeMillis() < expiryTimeMillis - 10000) {
                log.debug("Using cached Keycloak access token");
                return cachedToken;
            }
        }

        log.info("Requesting new Keycloak token from {}", tokenUrl);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "client_credentials");
        body.add("client_id", clientId);
        body.add("client_secret", clientSecret);

        try {
            ResponseEntity<TokenResponse> response = restTemplate.exchange(
                    tokenUrl, HttpMethod.POST,
                    new HttpEntity<>(body, headers),
                    TokenResponse.class);

            TokenResponse tokenResponse = response.getBody();
            if (tokenResponse == null || tokenResponse.getAccessToken() == null) {
                throw new DuxApiException("Keycloak returned empty token body", 502);
            }

            synchronized (lock) {
                cachedToken = tokenResponse.getAccessToken();
                long expiresIn = tokenResponse.getExpiresIn() != null ? tokenResponse.getExpiresIn() : 300L;
                expiryTimeMillis = System.currentTimeMillis() + (expiresIn * 1000L);
            }

            log.debug("Keycloak token obtained successfully");
            return tokenResponse.getAccessToken();

        } catch (RestClientException e) {
            log.error("Failed to obtain token from Keycloak: {}", e.getMessage());
            throw new DuxApiException("Failed to obtain access token: " + e.getMessage(), 502, e);
        }
    }
}
