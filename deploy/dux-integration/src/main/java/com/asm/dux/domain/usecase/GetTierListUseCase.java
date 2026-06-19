package com.asm.dux.domain.usecase;

import com.asm.dux.domain.model.TierFilter;
import com.asm.dux.domain.port.TierGateway;
import org.springframework.stereotype.Service;

@Service
public class GetTierListUseCase {

    private final TierGateway tierGateway;

    public GetTierListUseCase(TierGateway tierGateway) {
        this.tierGateway = tierGateway;
    }

    public String execute(TierFilter filter, String body) {
        // If the body is empty, we default to the standard pagination expected by DUX PHP
        if (body == null || body.trim().isEmpty() || "{}".equals(body.trim())) {
            body = "{\"first\":0,\"rows\":50,\"sortOrder\":1,\"filters\":{},\"globalFilter\":null,\"typeTier\":[\"1\"],\"checkMail\":false}";
        }
        return tierGateway.getTierList(filter, body);
    }
}
