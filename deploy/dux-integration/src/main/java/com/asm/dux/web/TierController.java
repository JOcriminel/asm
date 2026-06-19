package com.asm.dux.web;

import com.asm.dux.domain.model.TierFilter;
import com.asm.dux.domain.usecase.GetTierListUseCase;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/dux")
public class TierController {

    private final GetTierListUseCase getTierListUseCase;

    public TierController(GetTierListUseCase getTierListUseCase) {
        this.getTierListUseCase = getTierListUseCase;
    }

    @PostMapping("/tier/getAllTierByType/{typeTier}/{companyId}/{userId}/{startDate}/{endDate}/{p1}/{p2}/{p3}/{p4}/{p5}/{p6}/{dateTrans}/{p7}")
    public ResponseEntity<String> getAllTierByType(
            @PathVariable String typeTier,
            @PathVariable String companyId,
            @PathVariable String userId,
            @PathVariable String startDate,
            @PathVariable String endDate,
            @PathVariable String p1,
            @PathVariable String p2,
            @PathVariable String p3,
            @PathVariable String p4,
            @PathVariable String p5,
            @PathVariable String p6,
            @PathVariable String dateTrans,
            @PathVariable String p7,
            @RequestBody(required = false) String body) {

        log.info("POST /tier/getAllTierByType typeTier={} companyId={} userId={}", typeTier, companyId, userId);

        TierFilter filter = TierFilter.builder()
                .typeTier(typeTier)
                .companyId(companyId)
                .userId(userId)
                .startDate(startDate)
                .endDate(endDate)
                .p1(p1)
                .p2(p2)
                .p3(p3)
                .p4(p4)
                .p5(p5)
                .p6(p6)
                .dateTrans(dateTrans)
                .p7(p7)
                .build();

        String result = getTierListUseCase.execute(filter, body);
        return ResponseEntity.ok(result);
    }
}
