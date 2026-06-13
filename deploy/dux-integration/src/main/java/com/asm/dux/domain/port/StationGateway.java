package com.asm.dux.domain.port;

/**
 * Domain port — abstracts station lookup in the DUX ERP system.
 */
public interface StationGateway {
    String getStationById(String id);
}
