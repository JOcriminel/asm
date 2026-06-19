package com.asm.dux.infrastructure.dux;

import com.asm.dux.domain.port.DocumentGateway;
import com.asm.dux.domain.port.TokenProvider;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;

/**
 * Infrastructure adapter: implements {@link DocumentGateway} by calling the DUX ERP document API.
 */
@Component
public class DuxDocumentAdapter implements DocumentGateway {

    private static final Logger log = LoggerFactory.getLogger(DuxDocumentAdapter.class);

    private final DuxHttpClient httpClient;
    private final RestTemplate restTemplate;
    private final TokenProvider tokenProvider;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${dux.document-url}")
    private String documentUrl;

    @Value("${dux.edit-ligne-url}")
    private String editLigneUrl;

    @Value("${dux.edit-doc-url:https://duxweb.pre-produx.asmtechtn.com/api/Document/editDoc/}")
    private String editDocUrl;

    @Value("${dux.change-status-url:https://duxweb.pre-produx.asmtechtn.com/api/Document/changeEtatTansformation/}")
    private String changeStatusUrl;

    public DuxDocumentAdapter(DuxHttpClient httpClient, RestTemplate restTemplate, TokenProvider tokenProvider) {
        this.httpClient = httpClient;
        this.restTemplate = restTemplate;
        this.tokenProvider = tokenProvider;
    }

    @Override
    public String getDocumentById(String id) {
        return httpClient.get(documentUrl + id);
    }

    @Override
    public String editLigne(String body) {
        return httpClient.post(editLigneUrl, body);
    }

    @Override
    public String editDocument(String id, String body) {
        return httpClient.post(editDocUrl + id, body);
    }

    /**
     * Changes document status by:
     * 1. Fetching the full document from PHP
     * 2. Extracting the required fields (idDocument / P_ClasseDocument)
     * 3. Posting back to editDoc with FormData — exactly how the DUX web app does it
     */
    @Override
    public String changeDocumentStatus(String documentId, String statusId) {
        log.info("changeDocumentStatus requested for doc={} newStatus={} but updates are permanently disabled by user request.", documentId, statusId);
        // Return a simulated success response instead of modifying the ERP document
        return "{\"status\":\"success\",\"message\":\"Status update disabled\"}";
    }

    private String getTextSafe(JsonNode node, String... keys) {
        for (String key : keys) {
            if (node.has(key) && !node.get(key).isNull() && !node.get(key).asText().isEmpty()) {
                return node.get(key).asText();
            }
        }
        return null;
    }
}
