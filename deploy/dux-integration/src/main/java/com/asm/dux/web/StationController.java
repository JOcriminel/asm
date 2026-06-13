package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetStationByIdUseCase;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for station-related endpoints.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux")
public class StationController {

    private final GetStationByIdUseCase getStationByIdUseCase;

    public StationController(GetStationByIdUseCase getStationByIdUseCase) {
        this.getStationByIdUseCase = getStationByIdUseCase;
    }

    @GetMapping("/station/{id}")
    public ResponseEntity<String> getStation(@PathVariable String id) {
        log.info("GET /station/{}", id);
        String result = getStationByIdUseCase.execute(id);
        return ResponseEntity.ok(result);
    }
}
