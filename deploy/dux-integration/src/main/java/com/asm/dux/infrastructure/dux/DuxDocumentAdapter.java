package com.asm.dux.infrastructure.dux;

import com.asm.dux.domain.port.DocumentGateway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Infrastructure adapter: implements {@link DocumentGateway} by calling the DUX ERP document API.
 */
@Component
public class DuxDocumentAdapter implements DocumentGateway {

    private final DuxHttpClient httpClient;

    @Value("${dux.document-url}")
    private String documentUrl;

    @Value("${dux.edit-ligne-url}")
    private String editLigneUrl;

    public DuxDocumentAdapter(DuxHttpClient httpClient) {
        this.httpClient = httpClient;
    }

    @Override
    public String getDocumentById(String id) {
        return httpClient.get(documentUrl + id);
    }

    @Override
    public String editLigne(String body) {
        return httpClient.post(editLigneUrl, body);
    }
}
