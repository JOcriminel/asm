package com.asm.dux.domain.port;

/**
 * Domain port — abstracts serial number retrieval from the DUX ERP system.
 */
public interface NumSerieGateway {
    String getByNumBonSort(String idlignedocument);
    String deleteNumSerie(String id);
}
