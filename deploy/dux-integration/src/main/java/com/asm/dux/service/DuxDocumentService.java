package com.asm.dux.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class DuxDocumentService {

    private final RestTemplate restTemplate;
    private final DuxTokenService tokenService;

    @Value("${dux.document-url}")
    private String documentUrl;

    public DuxDocumentService(RestTemplate restTemplate, DuxTokenService tokenService) {
        this.restTemplate = restTemplate;
        this.tokenService = tokenService;
    }

    public String getDocumentById(String id) {
        String token = tokenService.getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.add("token", token);
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Void> requestEntity = new HttpEntity<>(headers);

        // Append the dynamic ID to the base document-url
        String fullUrl = documentUrl + id;

        ResponseEntity<String> response = restTemplate.exchange(
                fullUrl,
                HttpMethod.GET,
                requestEntity,
                String.class);

        return response.getBody();
    }
}
