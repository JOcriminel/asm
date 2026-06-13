package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.DocumentGateway;
import org.springframework.stereotype.Service;

/**
 * Use case — executes document line modifications via the DocumentGateway.
 */
@Service
public class EditLigneUseCase {

    private final DocumentGateway documentGateway;

    public EditLigneUseCase(DocumentGateway documentGateway) {
        this.documentGateway = documentGateway;
    }

    public String execute(String body) {
        return documentGateway.editLigne(body);
    }
}
