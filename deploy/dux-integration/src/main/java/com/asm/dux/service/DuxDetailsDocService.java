package com.asm.dux.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class DuxDetailsDocService {

    private final RestTemplate restTemplate;
    private final DuxTokenService tokenService;

    @Value("${dux.details-doc-url}")
    private String detailsDocUrl;

    public DuxDetailsDocService(RestTemplate restTemplate, DuxTokenService tokenService) {
        this.restTemplate = restTemplate;
        this.tokenService = tokenService;
    }

    public String getDetailsDoc(String from, String to, String idTier, String repres, 
                                String codeDoc, String idEtat, String all, 
                                String allDocuments, String idArticle, String AffichAvanc, 
                                String requestBody) {
        
        String token = tokenService.getAccessToken();

        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);
        headers.add("token", token);
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<String> requestEntity = new HttpEntity<>(requestBody, headers);

        // Build the dynamic URL with all variables
        String fullUrl = detailsDocUrl + from + "/" + to + "/" + idTier + "/" + repres + "/" 
                         + codeDoc + "/" + idEtat + "/" + all + "/" + allDocuments + "/" 
                         + idArticle + "/" + AffichAvanc;

        ResponseEntity<String> response = restTemplate.exchange(
                fullUrl,
                HttpMethod.POST,
                requestEntity,
                String.class);

        return response.getBody();
    }
}
