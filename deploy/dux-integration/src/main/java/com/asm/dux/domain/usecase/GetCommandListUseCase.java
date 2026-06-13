package com.asm.dux.domain.usecase;

import com.asm.dux.domain.model.DocumentFilter;
import com.asm.dux.domain.port.CommandListGateway;
import org.springframework.stereotype.Component;

/**
 * Application use-case: retrieve a filtered, paginated list of DUX commands.
 * Business rule: if no requestBody is provided, a sensible default is applied here
 * rather than scattered across the controller or adapter.
 */
@Component
public class GetCommandListUseCase {

    private static final String DEFAULT_REQUEST_BODY =
            "{\"idDocCommercial\":[],\"idTierModal\":null," +
            "\"event\":{\"first\":0,\"rows\":20,\"sortOrder\":1," +
            "\"filters\":{},\"globalFilter\":null}}";

    private final CommandListGateway commandListGateway;

    public GetCommandListUseCase(CommandListGateway commandListGateway) {
        this.commandListGateway = commandListGateway;
    }

    public String execute(DocumentFilter filter, String requestBody) {
        String body = (requestBody == null || requestBody.isBlank())
                ? DEFAULT_REQUEST_BODY
                : requestBody;
        return commandListGateway.getCommandList(filter, body);
    }
}
