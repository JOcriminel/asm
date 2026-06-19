package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.DocumentGateway;
import org.springframework.stereotype.Service;

@Service
public class EditDocumentUseCase {

    private final DocumentGateway documentGateway;

    public EditDocumentUseCase(DocumentGateway documentGateway) {
        this.documentGateway = documentGateway;
    }

    public String execute(String id, String body) {
        return documentGateway.editDocument(id, body);
    }
}
