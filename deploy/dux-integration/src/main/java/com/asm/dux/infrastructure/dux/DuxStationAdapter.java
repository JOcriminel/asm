package com.asm.dux.infrastructure.dux;

import com.asm.dux.domain.port.StationGateway;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Infrastructure adapter: implements {@link StationGateway} by calling the DUX ERP station API.
 */
@Component
public class DuxStationAdapter implements StationGateway {

    private final DuxHttpClient httpClient;

    @Value("${dux.station-url}")
    private String stationUrl;

    public DuxStationAdapter(DuxHttpClient httpClient) {
        this.httpClient = httpClient;
    }

    @Override
    public String getStationById(String id) {
        return httpClient.get(stationUrl + id);
    }
}
