package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.DocumentGateway;
import org.springframework.stereotype.Service;

@Service
public class ChangeDocumentStatusUseCase {

    private final DocumentGateway documentGateway;

    public ChangeDocumentStatusUseCase(DocumentGateway documentGateway) {
        this.documentGateway = documentGateway;
    }

    public String execute(String documentId, String statusId) {
        return documentGateway.changeDocumentStatus(documentId, statusId);
    }
}
