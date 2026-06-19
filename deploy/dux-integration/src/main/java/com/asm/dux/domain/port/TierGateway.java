package com.asm.dux.domain.port;

import com.asm.dux.domain.model.TierFilter;

public interface TierGateway {
    String getTierList(TierFilter filter, String body);
}
