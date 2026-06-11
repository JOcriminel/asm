package com.asm.dux.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class DuxStationService {

    private final RestTemplate restTemplate;
    private final DuxTokenService tokenService;

    @Value("${dux.station-url}")
    private String stationUrl;

    public DuxStationService(RestTemplate restTemplate, DuxTokenService tokenService) {
        this.restTemplate = restTemplate;
        this.tokenService = tokenService;
    }

    public String getStationById(String id) {
        String token = tokenService.getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.add("token", token);
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Void> requestEntity = new HttpEntity<>(headers);

        // Append the dynamic ID to the base station-url
        String fullUrl = stationUrl + id;

        ResponseEntity<String> response = restTemplate.exchange(
                fullUrl,
                HttpMethod.GET,
                requestEntity,
                String.class);

        return response.getBody();
    }
}
