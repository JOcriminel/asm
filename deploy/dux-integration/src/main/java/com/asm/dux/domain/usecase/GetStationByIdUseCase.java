package com.asm.dux.domain.usecase;

import com.asm.dux.domain.port.StationGateway;
import org.springframework.stereotype.Component;

/**
 * Application use-case: retrieve a DUX station by its identifier.
 */
@Component
public class GetStationByIdUseCase {

    private final StationGateway stationGateway;

    public GetStationByIdUseCase(StationGateway stationGateway) {
        this.stationGateway = stationGateway;
    }

    public String execute(String id) {
        return stationGateway.getStationById(id);
    }
}
