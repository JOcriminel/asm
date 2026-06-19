package com.asm.dux.domain.model;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TierFilter {
    private String typeTier;
    private String companyId;
    private String userId;
    private String startDate;
    private String endDate;
    private String p1;
    private String p2;
    private String p3;
    private String p4;
    private String p5;
    private String p6;
    private String dateTrans;
    private String p7;
}
