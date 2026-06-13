package com.asm.dux.web;

import com.asm.dux.domain.model.DocumentFilter;
import com.asm.dux.domain.usecase.GetCommandListUseCase;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for the filtered/paginated command list.
 * Path variables are kept identical to the old DuxController for full backwards compatibility.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux")
public class CommandListController {

    private final GetCommandListUseCase getCommandListUseCase;
    private final ObjectMapper objectMapper;

    public CommandListController(GetCommandListUseCase getCommandListUseCase) {
        this.getCommandListUseCase = getCommandListUseCase;
        this.objectMapper = new ObjectMapper();
    }

    @PostMapping("/list-documents/{from}/{to}/{idTier}/{repres}/{codeDoc}/{idEtat}/{all}/{allDocuments}/{idArticle}/{affichAvanc}")
    public ResponseEntity<String> listDocuments(
            @PathVariable String from,
            @PathVariable String to,
            @PathVariable String idTier,
            @PathVariable String repres,
            @PathVariable String codeDoc,
            @PathVariable String idEtat,
            @PathVariable String all,
            @PathVariable String allDocuments,
            @PathVariable String idArticle,
            @PathVariable String affichAvanc,
            @RequestParam(required = false) String stationId,
            @RequestBody(required = false) String body) {

        log.info("POST /list-documents from={} to={} idTier={} repres={} codeDoc={} stationId={}",
                from, to, idTier, repres, codeDoc, stationId);

        DocumentFilter filter = new DocumentFilter(
                from, to, idTier, repres, codeDoc,
                idEtat, all, allDocuments, idArticle, affichAvanc, stationId);

        String result = getCommandListUseCase.execute(filter, body);
        log.info("POST /list-documents response length={}", result != null ? result.length() : 0);
        return ResponseEntity.ok(result);
    }
}
