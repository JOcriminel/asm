package com.asm.dux.infrastructure.dux;

import com.asm.dux.domain.port.NumSerieGateway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Infrastructure adapter: implements {@link NumSerieGateway} by calling the DUX ERP serial number API.
 */
@Component
public class DuxNumSerieAdapter implements NumSerieGateway {

    private final DuxHttpClient httpClient;

    @Value("${dux.num-serie-url}")
    private String numSerieUrl;

    @Value("${dux.delete-num-serie-url}")
    private String deleteNumSerieUrl;

    public DuxNumSerieAdapter(DuxHttpClient httpClient) {
        this.httpClient = httpClient;
    }

    @Override
    public String getByNumBonSort(String idlignedocument) {
        return httpClient.get(numSerieUrl + idlignedocument);
    }

    @Override
    public String deleteNumSerie(String id) {
        return httpClient.delete(deleteNumSerieUrl + id);
    }
}
