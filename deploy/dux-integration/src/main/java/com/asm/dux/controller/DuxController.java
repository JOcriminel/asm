package com.asm.dux.controller;

import com.asm.dux.service.DuxUserService;
import com.asm.dux.service.DuxStationService;
import com.asm.dux.service.DuxDocumentService;
import com.asm.dux.service.DuxDetailsDocService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;

@RestController
@RequestMapping("/api/dux")
public class DuxController {

    private final DuxUserService userService;
    private final DuxStationService stationService;
    private final DuxDocumentService documentService;
    private final DuxDetailsDocService detailsDocService;

    public DuxController(DuxUserService userService, DuxStationService stationService, 
                         DuxDocumentService documentService, DuxDetailsDocService detailsDocService) {
        this.userService = userService;
        this.stationService = stationService;
        this.documentService = documentService;
        this.detailsDocService = detailsDocService;
    }

    @GetMapping("/user")
    public ResponseEntity<String> user(
            @RequestParam(defaultValue = "admin") String login) {

        try {
            String result = userService.getUserByLogin(login);
            return ResponseEntity.ok(result);

        } catch (RestClientException e) {
            // HTTP call failed (timeout, connection refused, 4xx/5xx from remote)
            String msg = """            
                    {"error": "DUX API call failed", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(502).body(msg);

        } catch (Exception e) {
            // Any other unexpected error
            String msg = """
                    {"error": "Internal error", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(500).body(msg);
        }
    }

    @GetMapping("/station/{id}")
    public ResponseEntity<String> station(@PathVariable String id) {
        try {
            String result = stationService.getStationById(id);
            return ResponseEntity.ok(result);

        } catch (RestClientException e) {
            // HTTP call failed (timeout, connection refused, 4xx/5xx from remote)
            String msg = """            
                    {"error": "DUX API call failed", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(502).body(msg);

        } catch (Exception e) {
            // Any other unexpected error
            String msg = """
                    {"error": "Internal error", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(500).body(msg);
        }
    }

    @GetMapping("/document/{id}")
    public ResponseEntity<String> document(@PathVariable String id) {
        try {
            String result = documentService.getDocumentById(id);
            return ResponseEntity.ok(result);

        } catch (RestClientException e) {
            // HTTP call failed (timeout, connection refused, 4xx/5xx from remote)
            String msg = """            
                    {"error": "DUX API call failed", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(502).body(msg);

        } catch (Exception e) {
            // Any other unexpected error
            String msg = """
                    {"error": "Internal error", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(500).body(msg);
        }
    }

    @PostMapping("/detailsDoc2/{from}/{to}/{idTier}/{repres}/{codeDoc}/{idEtat}/{all}/{allDocuments}/{idArticle}/{AffichAvanc}")
    public ResponseEntity<String> detailsDoc2(
            @PathVariable String from,
            @PathVariable String to,
            @PathVariable String idTier,
            @PathVariable String repres,
            @PathVariable String codeDoc,
            @PathVariable String idEtat,
            @PathVariable String all,
            @PathVariable String allDocuments,
            @PathVariable String idArticle,
            @PathVariable String AffichAvanc,
            @RequestBody(required = false) String body) {
        try {
            String result = detailsDocService.getDetailsDoc(from, to, idTier, repres, codeDoc, 
                                                            idEtat, all, allDocuments, idArticle, 
                                                            AffichAvanc, body);
            return ResponseEntity.ok(result);

        } catch (RestClientException e) {
            // HTTP call failed (timeout, connection refused, 4xx/5xx from remote)
            String msg = """            
                    {"error": "DUX API call failed", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(502).body(msg);

        } catch (Exception e) {
            // Any other unexpected error
            String msg = """
                    {"error": "Internal error", "detail": "%s"}
                    """.formatted(e.getMessage().replace("\"", "'"));
            return ResponseEntity.status(500).body(msg);
        }
    }
}