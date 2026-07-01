package com.asm.dux.web;

import com.asm.dux.domain.model.ScreenConfig;
import com.asm.dux.dto.ScreenConfigDto;
import com.asm.dux.infrastructure.db.repository.ScreenConfigRepository;
import com.asm.dux.infrastructure.dux.DuxHttpClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/dux/screen-configs")
public class ScreenConfigController {

    private final ScreenConfigRepository repository;
    private final DuxHttpClient duxHttpClient;
    private final ObjectMapper objectMapper;

    @Value("${dux.classe-doc-url}")
    private String classeDocUrl;

    public ScreenConfigController(ScreenConfigRepository repository, DuxHttpClient duxHttpClient) {
        this.repository = repository;
        this.duxHttpClient = duxHttpClient;
        this.objectMapper = new ObjectMapper();
    }

    @GetMapping("/available-classes")
    public ResponseEntity<List<Map<String, Object>>> getAvailableClasses() {
        log.info("GET /api/dux/screen-configs/available-classes");
        List<Map<String, Object>> result = new ArrayList<>();
        try {
            String responseBody = duxHttpClient.get(classeDocUrl);
            if (responseBody != null && !responseBody.isBlank()) {
                JsonNode root = objectMapper.readTree(responseBody);
                JsonNode array = null;
                if (root.isArray()) {
                    array = root;
                } else if (root.isObject()) {
                    for (String key : new String[]{"data", "content", "results", "classes"}) {
                        if (root.has(key) && root.get(key).isArray()) {
                            array = root.get(key);
                            break;
                        }
                    }
                }

                if (array != null && array.isArray()) {
                    List<ScreenConfig> configured = repository.findAll();
                    Set<String> configuredTypes = new HashSet<>();
                    for (ScreenConfig sc : configured) {
                        configuredTypes.add(sc.getDocumentType().toUpperCase().trim());
                    }

                    for (JsonNode item : array) {
                        String code = "";
                        if (item.has("codeClasseDoc") && !item.get("codeClasseDoc").isNull()) {
                            code = item.get("codeClasseDoc").asText().trim();
                        } else if (item.has("code") && !item.get("code").isNull()) {
                            code = item.get("code").asText().trim();
                        }

                        String libelle = code;
                        if (item.has("libelleClasseDoc") && !item.get("libelleClasseDoc").isNull()) {
                            libelle = item.get("libelleClasseDoc").asText().trim();
                        } else if (item.has("libelle") && !item.get("libelle").isNull()) {
                            libelle = item.get("libelle").asText().trim();
                        }

                        if (!code.isBlank() && !configuredTypes.contains(code.toUpperCase())) {
                            Map<String, Object> map = new HashMap<>();
                            map.put("code", code);
                            map.put("libelle", libelle);
                            result.add(map);
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to fetch available document classes from DUX", e);
        }
        return ResponseEntity.ok(result);
    }

    @GetMapping("/all-document-classes")
    public ResponseEntity<List<Map<String, Object>>> getAllDocumentClasses() {
        log.info("GET /api/dux/screen-configs/all-document-classes");
        List<Map<String, Object>> result = new ArrayList<>();
        try {
            String responseBody = duxHttpClient.get(classeDocUrl);
            if (responseBody != null && !responseBody.isBlank()) {
                JsonNode root = objectMapper.readTree(responseBody);
                JsonNode array = null;
                if (root.isArray()) {
                    array = root;
                } else if (root.isObject()) {
                    for (String key : new String[]{"data", "content", "results", "classes"}) {
                        if (root.has(key) && root.get(key).isArray()) {
                            array = root.get(key);
                            break;
                        }
                    }
                }

                if (array != null && array.isArray()) {
                    for (JsonNode item : array) {
                        String code = "";
                        if (item.has("codeClasseDoc") && !item.get("codeClasseDoc").isNull()) {
                            code = item.get("codeClasseDoc").asText().trim();
                        } else if (item.has("code") && !item.get("code").isNull()) {
                            code = item.get("code").asText().trim();
                        }

                        String libelle = code;
                        if (item.has("libelleClasseDoc") && !item.get("libelleClasseDoc").isNull()) {
                            libelle = item.get("libelleClasseDoc").asText().trim();
                        } else if (item.has("libelle") && !item.get("libelle").isNull()) {
                            libelle = item.get("libelle").asText().trim();
                        }

                        if (!code.isBlank()) {
                            Map<String, Object> map = new HashMap<>();
                            map.put("code", code);
                            map.put("libelle", libelle);
                            result.add(map);
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to fetch all document classes from DUX", e);
        }
        return ResponseEntity.ok(result);
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
        config.setEnableChecklistTracking(dto.isEnableChecklistTracking());
        config.setDetailPageTitle(dto.getDetailPageTitle());
        config.setHidePricesForOperateurs(dto.isHidePricesForOperateurs());
        config.setHidePrices(dto.isHidePrices());
        
        // New fields
        config.setPrimaryColor(dto.getPrimaryColor());
        config.setRequireSignature(dto.isRequireSignature());
        config.setRequirePhoto(dto.isRequirePhoto());
        config.setDefaultSortField(dto.getDefaultSortField());
        config.setEnableSoundAlerts(dto.isEnableSoundAlerts());
        config.setEnableVibrationAlerts(dto.isEnableVibrationAlerts());
        config.setActive(dto.isActive());
        config.setCategory(dto.getCategory());
        config.setDetailsFieldsConfig(dto.getDetailsFieldsConfig());
        config.setCardFieldsConfig(dto.getCardFieldsConfig());
        config.setSearchFieldsConfig(dto.getSearchFieldsConfig());
        config.setCustomFinalizeMessage(dto.getCustomFinalizeMessage());
        
        if (dto.getHidePricesForRoles() != null) {
            config.setHidePricesForRoles(String.join(",", dto.getHidePricesForRoles()));
        } else {
            config.setHidePricesForRoles("");
        }

        config.setStatusFilters(dto.getStatusFilters());
        
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

    @GetMapping("/classe-doc/check-serial/{code}")
    public ResponseEntity<Map<String, Object>> checkSerialDoc(@PathVariable String code) {
        log.info("GET /api/dux/screen-configs/classe-doc/check-serial/{}", code);
        Map<String, Object> result = new HashMap<>();
        result.put("code", code);
        result.put("allowed", false);
        result.put("reason", "Classe de document introuvable.");

        String lookupCode = code;
        if ("BP".equalsIgnoreCase(code)) {
            lookupCode = "DPR";
        }

        try {
            String responseBody = duxHttpClient.get(classeDocUrl);
            if (responseBody != null && !responseBody.isBlank()) {
                JsonNode root = objectMapper.readTree(responseBody);
                JsonNode array = null;
                if (root.isArray()) {
                    array = root;
                } else if (root.isObject()) {
                    for (String key : new String[]{"data", "content", "results", "classes"}) {
                        if (root.has(key) && root.get(key).isArray()) {
                            array = root.get(key);
                            break;
                        }
                    }
                }
                
                String docId = null;
                if (array != null && array.isArray()) {
                    for (JsonNode item : array) {
                        String c = item.has("codeClasseDoc") ? item.get("codeClasseDoc").asText().trim() : (item.has("code") ? item.get("code").asText().trim() : "");
                        if (c.equalsIgnoreCase(lookupCode)) {
                            docId = item.has("id") ? item.get("id").asText().trim() : (item.has("idClasseDoc") ? item.get("idClasseDoc").asText().trim() : "");
                            break;
                        }
                    }
                }

                if (docId != null && !docId.isBlank()) {
                    String findUrl = "https://duxweb.pre-produx.asmtechtn.com/api/classeDoc/findByID/" + docId;
                    String detailsJson = duxHttpClient.get(findUrl);
                    if (detailsJson != null && !detailsJson.isBlank()) {
                        JsonNode details = objectMapper.readTree(detailsJson);
                        boolean numeroserie = false;
                        for (String nsKey : new String[]{"numeroserie", "numeroSerie", "numero_serie"}) {
                            if (details.has(nsKey) && !details.get(nsKey).isNull()) {
                                String textVal = details.get(nsKey).asText().trim();
                                numeroserie = details.get(nsKey).asBoolean() || "1".equals(textVal) || "true".equalsIgnoreCase(textVal) || "oui".equalsIgnoreCase(textVal);
                            }
                        }
                        result.put("allowed", numeroserie);
                        result.put("id", docId);
                        if (!numeroserie) {
                            result.put("reason", "La classe de document " + code + " (ID: " + docId + ") n'a pas l'option 'numeroserie' activée dans l'API DUX.");
                        } else {
                            result.put("reason", "");
                        }
                    } else {
                        result.put("reason", "Impossible de récupérer les détails de la classe " + code + " (ID: " + docId + ") depuis DUX ERP.");
                    }
                } else {
                    result.put("reason", "Aucune classe de document correspondante trouvée sur DUX ERP pour le code : " + code);
                }
            } else {
                result.put("reason", "Impossible de se connecter à DUX ERP pour récupérer la liste des classes.");
            }
        } catch (Exception e) {
            log.error("Failed to check class doc serial permission for " + code, e);
            result.put("reason", "Erreur de communication : " + e.getMessage());
        }
        return ResponseEntity.ok(result);
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
        bc.setEnableChecklistTracking(false);
        bc.setVisibleRoles("admin,commercial,operateur");
        bc.setDetailPageTitle("BC-D");
        bc.setHidePricesForOperateurs(false);
        bc.setHidePrices(false);
        bc.setHidePricesForRoles("");
        bc.setStatusFilters("all:Tout,1:NT,2:PT,3:TT");
        bc.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
        bc.setPrimaryColor("#2196F3"); // Blue
        bc.setRequireSignature(false);
        bc.setRequirePhoto(false);
        bc.setDefaultSortField("date");
        bc.setEnableSoundAlerts(true);
        bc.setEnableVibrationAlerts(true);
        bc.setCategory("Gestion de Vente");
        defaults.add(bc);

        // BP
        ScreenConfig bp = new ScreenConfig();
        bp.setDocumentType("BP");
        bp.setPageTitle("Bon de Préparation");
        bp.setSearchHint("Search code, customer or representative...");
        bp.setEnableBarcodeScanner(true);
        bp.setEnablePdfPrinting(false);
        bp.setEnableSerialNumberTracking(true);
        bp.setEnableChecklistTracking(true);
        bp.setVisibleRoles("admin,commercial,operateur");
        bp.setDetailPageTitle("BP-D");
        bp.setHidePricesForOperateurs(false);
        bp.setHidePrices(false);
        bp.setHidePricesForRoles("");
        bp.setStatusFilters("all:Tout,1:NT,2:PT,3:TT");
        bp.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
        bp.setPrimaryColor("#4CAF50"); // Green
        bp.setRequireSignature(false);
        bp.setRequirePhoto(true); // require photo proof by default
        bp.setDefaultSortField("status");
        bp.setEnableSoundAlerts(true);
        bp.setEnableVibrationAlerts(true);
        bp.setCategory("Gestion de Vente");
        defaults.add(bp);

        // BS
        ScreenConfig bs = new ScreenConfig();
        bs.setDocumentType("BS");
        bs.setPageTitle("Bon de Sortie");
        bs.setSearchHint("Rechercher code, client ou représentant...");
        bs.setEnableBarcodeScanner(false);
        bs.setEnablePdfPrinting(false);
        bs.setEnableSerialNumberTracking(false);
        bs.setEnableChecklistTracking(false);
        bs.setVisibleRoles("admin,commercial,operateur");
        bs.setDetailPageTitle("BS-D");
        bs.setHidePricesForOperateurs(false);
        bs.setHidePrices(false);
        bs.setHidePricesForRoles("");
        bs.setStatusFilters("all:Tout,1:NT,2:PT,3:TT");
        bs.setAllowedRolesToFinalize("admin,commercial,operateur,Administrateur,Commercial,Opérateur");
        bs.setPrimaryColor("#FF9800"); // Orange
        bs.setRequireSignature(true); // require signature on exit by default
        bs.setRequirePhoto(false);
        bs.setDefaultSortField("date");
        bs.setEnableSoundAlerts(true);
        bs.setEnableVibrationAlerts(true);
        bs.setCategory("Gestion de Vente");
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
        dto.setEnableChecklistTracking(entity.isEnableChecklistTracking());
        dto.setDetailPageTitle(entity.getDetailPageTitle());
        dto.setHidePricesForOperateurs(entity.isHidePricesForOperateurs());
        dto.setHidePrices(entity.isHidePrices());
        
        // New fields
        dto.setPrimaryColor(entity.getPrimaryColor());
        dto.setRequireSignature(entity.isRequireSignature());
        dto.setRequirePhoto(entity.isRequirePhoto());
        dto.setDefaultSortField(entity.getDefaultSortField());
        dto.setEnableSoundAlerts(entity.isEnableSoundAlerts());
        dto.setEnableVibrationAlerts(entity.isEnableVibrationAlerts());
        dto.setActive(entity.getActive());
        dto.setCategory(entity.getCategory());
        dto.setDetailsFieldsConfig(entity.getDetailsFieldsConfig());
        dto.setCardFieldsConfig(entity.getCardFieldsConfig());
        dto.setSearchFieldsConfig(entity.getSearchFieldsConfig());
        dto.setCustomFinalizeMessage(entity.getCustomFinalizeMessage());

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

        if (entity.getHidePricesForRoles() != null && !entity.getHidePricesForRoles().trim().isEmpty()) {
            dto.setHidePricesForRoles(Arrays.asList(entity.getHidePricesForRoles().split(",")));
        } else {
            dto.setHidePricesForRoles(new ArrayList<>());
        }

        dto.setStatusFilters(entity.getStatusFilters());

        return dto;
    }

    @DeleteMapping("/{docType}")
    public ResponseEntity<Void> deleteConfig(@PathVariable String docType) {
        log.info("DELETE /api/dux/screen-configs/{}", docType);
        
        // Prevent deleting predefined core configs
        List<String> coreTypes = Arrays.asList("BC", "BP", "BPR", "BS", "HOME");
        if (coreTypes.contains(docType.toUpperCase())) {
            return ResponseEntity.badRequest().build();
        }
        
        if (repository.existsById(docType)) {
            repository.deleteById(docType);
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }
}
