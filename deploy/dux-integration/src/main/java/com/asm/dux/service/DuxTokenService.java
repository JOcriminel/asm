package com.asm.dux.service;

import com.asm.dux.dto.TokenResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Service
@Slf4j
public class DuxTokenService {

    private final RestTemplate restTemplate;

    public DuxTokenService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @Value("${dux.token-url}")
    private String tokenUrl;

    @Value("${dux.client-id}")
    private String clientId;

    @Value("${dux.client-secret}")
    private String clientSecret;

    public String getAccessToken() {
        log.info("Requesting Keycloak token from URL: {}", tokenUrl);
        log.info("Using client_id: {}", clientId);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("grant_type", "client_credentials");
        body.add("client_id", clientId);
        body.add("client_secret", clientSecret);

        HttpEntity<?> request = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<TokenResponse> response = restTemplate.exchange(
                    tokenUrl,
                    HttpMethod.POST,
                    request,
                    TokenResponse.class);

            if (response.getBody() != null && response.getBody().getAccessToken() != null) {
                log.info("Successfully retrieved access token from Keycloak");
                return response.getBody().getAccessToken();
            } else {
                log.warn("Keycloak response was successful but access_token was missing in body");
                return null;
            }
        } catch (RestClientException e) {
            log.error("Failed to retrieve token from Keycloak. Error: {}", e.getMessage());
            throw e;
        }
    }
}