package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.NumSerieGateway;
import org.springframework.stereotype.Component;

/**
 * Application use-case: retrieve serial numbers for a given sort document ID from DUX ERP.
 */
@Component
public class GetNumSerieByBonSortUseCase {

    private final NumSerieGateway numSerieGateway;

    public GetNumSerieByBonSortUseCase(NumSerieGateway numSerieGateway) {
        this.numSerieGateway = numSerieGateway;
    }

    public String execute(String idlignedocument) {
        return numSerieGateway.getByNumBonSort(idlignedocument);
    }
}
