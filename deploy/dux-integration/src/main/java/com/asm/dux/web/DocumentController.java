package com.asm.dux.web;

import com.asm.dux.domain.usecase.GetDocumentByIdUseCase;
import com.asm.dux.domain.usecase.EditLigneUseCase;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for single-document retrieval.
 */
@Slf4j
@RestController
@RequestMapping("/api/dux")
public class DocumentController {

    private final GetDocumentByIdUseCase getDocumentByIdUseCase;
    private final EditLigneUseCase editLigneUseCase;

    public DocumentController(GetDocumentByIdUseCase getDocumentByIdUseCase, EditLigneUseCase editLigneUseCase) {
        this.getDocumentByIdUseCase = getDocumentByIdUseCase;
        this.editLigneUseCase = editLigneUseCase;
    }

    @GetMapping("/document/{id}")
    public ResponseEntity<String> getDocument(@PathVariable String id) {
        log.info("GET /document/{}", id);
        String result = getDocumentByIdUseCase.execute(id);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/Document/editLigne")
    public ResponseEntity<String> editLigne(@RequestBody String body) {
        log.info("POST /Document/editLigne");
        String result = editLigneUseCase.execute(body);
        return ResponseEntity.ok(result);
    }
}
