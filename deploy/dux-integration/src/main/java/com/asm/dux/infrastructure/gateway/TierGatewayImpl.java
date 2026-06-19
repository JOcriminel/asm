package com.asm.dux.infrastructure.gateway;

import com.asm.dux.domain.model.TierFilter;
import com.asm.dux.domain.port.TierGateway;
import com.asm.dux.infrastructure.dux.DuxHttpClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class TierGatewayImpl implements TierGateway {

    private final DuxHttpClient httpClient;
    private final String dspApiUrl;

    public TierGatewayImpl(DuxHttpClient httpClient,
                           @Value("${dsp.api.url:https://duxweb.pre-produx.asmtechtn.com}") String dspApiUrl) {
        this.httpClient = httpClient;
        this.dspApiUrl = dspApiUrl;
    }

    @Override
    public String getTierList(TierFilter filter, String body) {
        // Construct the URL exactly as the PHP API expects:
        // /api/tier/getAllTierByType/{typeTier}/{companyId}/{userId}/{startDate}/{endDate}/{p1}/{p2}/{p3}/{p4}/{p5}/{p6}/{dateTrans}/{p7}
        String path = String.format("/api/tier/getAllTierByType/%s/%s/%s/%s/%s/%s/%s/%s/%s/%s/%s/%s/%s",
                filter.getTypeTier(),
                filter.getCompanyId(),
                filter.getUserId(),
                filter.getStartDate(),
                filter.getEndDate(),
                filter.getP1(),
                filter.getP2(),
                filter.getP3(),
                filter.getP4(),
                filter.getP5(),
                filter.getP6(),
                filter.getDateTrans(),
                filter.getP7());

        String fullUrl = dspApiUrl + path;
        log.info("Calling DUX PHP API for tiers: {}", fullUrl);

        try {
            return httpClient.post(fullUrl, body);
        } catch (Exception e) {
            log.error("Failed to fetch tier list from DUX PHP API", e);
            throw new RuntimeException("Error communicating with Tier API", e);
        }
    }
}
