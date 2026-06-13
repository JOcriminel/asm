package com.asm.dux.domain.port;

import com.asm.dux.domain.model.DocumentFilter;

/**
 * Domain port — abstracts the paginated/filtered command-list query.
 */
public interface CommandListGateway {
    String getCommandList(DocumentFilter filter, String requestBody);
}
