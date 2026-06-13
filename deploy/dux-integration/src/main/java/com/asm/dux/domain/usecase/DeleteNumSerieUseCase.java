package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.NumSerieGateway;
import org.springframework.stereotype.Component;

/**
 * Application use-case: delete a serial number by its unique identifier in DUX ERP.
 */
@Component
public class DeleteNumSerieUseCase {

    private final NumSerieGateway numSerieGateway;

    public DeleteNumSerieUseCase(NumSerieGateway numSerieGateway) {
        this.numSerieGateway = numSerieGateway;
    }

    public String execute(String id) {
        return numSerieGateway.deleteNumSerie(id);
    }
}
