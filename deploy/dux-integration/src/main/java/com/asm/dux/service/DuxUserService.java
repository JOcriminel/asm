package com.asm.dux.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class DuxUserService {

    private final RestTemplate restTemplate;
    private final DuxTokenService tokenService;

    @Value("${dux.user-url}")
    private String userUrl;

    public DuxUserService(RestTemplate restTemplate,
            DuxTokenService tokenService) {
        this.restTemplate = restTemplate;
        this.tokenService = tokenService;
    }

    public String getUserByLogin(String login) {

        String token = tokenService.getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.add("token", token);
        headers.setContentType(MediaType.APPLICATION_JSON);

        com.asm.dux.dto.UserLoginRequest body = new com.asm.dux.dto.UserLoginRequest(login);

        HttpEntity<com.asm.dux.dto.UserLoginRequest> request = new HttpEntity<>(body, headers);

        ResponseEntity<String> response = restTemplate.exchange(
                userUrl,
                HttpMethod.POST,
                request,
                String.class);

        return response.getBody();
    }
}