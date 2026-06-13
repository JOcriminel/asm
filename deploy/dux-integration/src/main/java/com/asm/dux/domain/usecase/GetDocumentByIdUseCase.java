package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.DocumentGateway;
import org.springframework.stereotype.Component;

/**
 * Application use-case: retrieve a single DUX document by its identifier.
 */
@Component
public class GetDocumentByIdUseCase {

    private final DocumentGateway documentGateway;

    public GetDocumentByIdUseCase(DocumentGateway documentGateway) {
        this.documentGateway = documentGateway;
    }

    public String execute(String id) {
        return documentGateway.getDocumentById(id);
    }
}
