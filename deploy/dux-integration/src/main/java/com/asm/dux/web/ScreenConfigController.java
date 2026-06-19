package com.asm.dux.web;

import com.asm.dux.domain.model.ScreenConfig;
import com.asm.dux.dto.ScreenConfigDto;
import com.asm.dux.infrastructure.db.repository.ScreenConfigRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/dux/screen-configs")
public class ScreenConfigController {

    private final ScreenConfigRepository repository;

    public ScreenConfigController(ScreenConfigRepository repository) {
        this.repository = repository;
    }

    @GetMapping
    public ResponseEntity<Map<String, ScreenConfigDto>> getConfigs() {
        log.info("GET /api/dux/screen-configs");
        List<ScreenConfig> list = repository.findAll();
        
        // If empty, initialize defaults
        if (list.isEmpty()) {
            log.info("No screen configurations found in database. Initializing defaults...");
            list = initializeDefaultConfigs();
        }

        Map<String, ScreenConfigDto> result = new HashMap<>();
        for (ScreenConfig config : list) {
            result.put(config.getDocumentType(), toDto(config));
        }
        return ResponseEntity.ok(result);
    }

    @PutMapping("/{docType}")
    public ResponseEntity<ScreenConfigDto> updateConfig(@PathVariable String docType, @RequestBody ScreenConfigDto dto) {
        log.info("PUT /api/dux/screen-configs/{}", docType);
        
        ScreenConfig config = repository.findById(docType).orElse(new ScreenConfig());
        config.setDocumentType(docType);
        config.setPageTitle(dto.getPageTitle());
        config.setSearchHint(dto.getSearchHint());
        config.setEnableBarcodeScanner(dto.isEnableBarcodeScanner());
        config.setEnablePdfPrinting(dto.isEnablePdfPrinting());
        config.setEnableSerialNumberTracking(dto.isEnableSerialNumberTracking());
        config.setDetailPageTitle(dto.getDetailPageTitle());
        config.setHidePricesForOperateurs(dto.isHidePricesForOperateurs());
        
        // New fields
        config.setPrimaryColor(dto.getPrimaryColor());
        config.setRequireSignature(dto.isRequireSignature());
        config.setRequirePhoto(dto.isRequirePhoto());
        config.setDefaultSortField(dto.getDefaultSortField());
        
        if (dto.getVisibleRoles() != null) {
            config.setVisibleRoles(String.join(",", dto.getVisibleRoles()));
        } else {
            config.setVisibleRoles("");
        }

        if (dto.getAllowedRolesToFinalize() != null) {
            config.setAllowedRolesToFinalize(String.join(",", dto.getAllowedRolesToFinalize()));
        } else {
            config.setAllowedRolesToFinalize("");
        }

        ScreenConfig saved = repository.save(config);
        return ResponseEntity.ok(toDto(saved));
    }

    private List<ScreenConfig> initializeDefaultConfigs() {
        List<ScreenConfig> defaults = new ArrayList<>();

        // BC
        ScreenConfig bc = new ScreenConfig();
        bc.setDocumentType("BC");
        bc.setPageTitle("Bon de Commande");
        bc.setSearchHint("Search code, customer or representative...");
        bc.setEnableBarcodeScanner(false);
        bc.setEnablePdfPrinting(true);
        bc.setEnableSerialNumberTracking(false);
        bc.setVisibleRoles("admin,commercial,operateur");
        bc.setDetailPageTitle("BC-D");
        bc.setHidePricesForOperateurs(false);
        bc.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
        bc.setPrimaryColor("#2196F3"); // Blue
        bc.setRequireSignature(false);
        bc.setRequirePhoto(false);
        bc.setDefaultSortField("date");
        defaults.add(bc);

        // BP
        ScreenConfig bp = new ScreenConfig();
        bp.setDocumentType("BP");
        bp.setPageTitle("Bon de Préparation");
        bp.setSearchHint("Search code, customer or representative...");
        bp.setEnableBarcodeScanner(true);
        bp.setEnablePdfPrinting(false);
        bp.setEnableSerialNumberTracking(true);
        bp.setVisibleRoles("admin,commercial,operateur");
        bp.setDetailPageTitle("BP-D");
        bp.setHidePricesForOperateurs(false);
        bp.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
        bp.setPrimaryColor("#4CAF50"); // Green
        bp.setRequireSignature(false);
        bp.setRequirePhoto(true); // require photo proof by default
        bp.setDefaultSortField("status");
        defaults.add(bp);

        // BS
        ScreenConfig bs = new ScreenConfig();
        bs.setDocumentType("BS");
        bs.setPageTitle("Bon de Sortie");
        bs.setSearchHint("Rechercher code, client ou représentant...");
        bs.setEnableBarcodeScanner(false);
        bs.setEnablePdfPrinting(false);
        bs.setEnableSerialNumberTracking(false);
        bs.setVisibleRoles("admin,commercial,operateur");
        bs.setDetailPageTitle("BS-D");
        bs.setHidePricesForOperateurs(false);
        bs.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
        bs.setPrimaryColor("#FF9800"); // Orange
        bs.setRequireSignature(true); // require signature on exit by default
        bs.setRequirePhoto(false);
        bs.setDefaultSortField("date");
        defaults.add(bs);

        return repository.saveAll(defaults);
    }

    private ScreenConfigDto toDto(ScreenConfig entity) {
        ScreenConfigDto dto = new ScreenConfigDto();
        dto.setDocumentType(entity.getDocumentType());
        dto.setPageTitle(entity.getPageTitle());
        dto.setSearchHint(entity.getSearchHint());
        dto.setEnableBarcodeScanner(entity.isEnableBarcodeScanner());
        dto.setEnablePdfPrinting(entity.isEnablePdfPrinting());
        dto.setEnableSerialNumberTracking(entity.isEnableSerialNumberTracking());
        dto.setDetailPageTitle(entity.getDetailPageTitle());
        dto.setHidePricesForOperateurs(entity.isHidePricesForOperateurs());
        
        // New fields
        dto.setPrimaryColor(entity.getPrimaryColor());
        dto.setRequireSignature(entity.isRequireSignature());
        dto.setRequirePhoto(entity.isRequirePhoto());
        dto.setDefaultSortField(entity.getDefaultSortField());

        if (entity.getVisibleRoles() != null && !entity.getVisibleRoles().trim().isEmpty()) {
            dto.setVisibleRoles(Arrays.asList(entity.getVisibleRoles().split(",")));
        } else {
            dto.setVisibleRoles(new ArrayList<>());
        }

        if (entity.getAllowedRolesToFinalize() != null && !entity.getAllowedRolesToFinalize().trim().isEmpty()) {
            dto.setAllowedRolesToFinalize(Arrays.asList(entity.getAllowedRolesToFinalize().split(",")));
        } else {
            dto.setAllowedRolesToFinalize(new ArrayList<>());
        }

        return dto;
    }
}
