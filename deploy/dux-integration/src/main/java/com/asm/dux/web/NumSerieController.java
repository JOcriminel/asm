package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetNumSerieByBonSortUseCase;
import com.asm.dux.domain.usecase.DeleteNumSerieUseCase;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for DUX ERP serial number queries and actions.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux")
public class NumSerieController {

    private final GetNumSerieByBonSortUseCase getNumSerieByBonSortUseCase;
    private final DeleteNumSerieUseCase deleteNumSerieUseCase;

    public NumSerieController(
            GetNumSerieByBonSortUseCase getNumSerieByBonSortUseCase,
            DeleteNumSerieUseCase deleteNumSerieUseCase) {
        this.getNumSerieByBonSortUseCase = getNumSerieByBonSortUseCase;
        this.deleteNumSerieUseCase = deleteNumSerieUseCase;
    }

    @GetMapping("/numSerie/getByNumBonSort/{idlignedocument}")
    public ResponseEntity<String> getByNumBonSort(@PathVariable String idlignedocument) {
        log.info("GET /numSerie/getByNumBonSort/{}", idlignedocument);
        String result = getNumSerieByBonSortUseCase.execute(idlignedocument);
        return ResponseEntity.ok(result);
    }

    @DeleteMapping("/numSerie/delete/{id}")
    public ResponseEntity<String> deleteNumSerie(@PathVariable String id) {
        log.info("DELETE /numSerie/delete/{}", id);
        String result = deleteNumSerieUseCase.execute(id);
        return ResponseEntity.ok(result);
    }
}
