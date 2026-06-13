package com.asm.dux.domain.port;

/**
 * Domain port — abstracts single-document retrieval from the DUX ERP system.
 */
public interface DocumentGateway {
    String getDocumentById(String id);
    String editLigne(String body);
}
