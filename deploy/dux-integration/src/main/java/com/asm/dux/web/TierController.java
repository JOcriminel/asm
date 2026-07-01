package com.asm.dux.web;

import com.asm.dux.domain.model.TierFilter;
import com.asm.dux.domain.usecase.GetTierListUseCase;
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
@RequestMapping("/api/dux")
public class TierController {

    private final GetTierListUseCase getTierListUseCase;
    private final DuxHttpClient duxHttpClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Value("${dux.type-tier-url}")
    private String typeTierUrl;

    public TierController(GetTierListUseCase getTierListUseCase, DuxHttpClient duxHttpClient) {
        this.getTierListUseCase = getTierListUseCase;
        this.duxHttpClient = duxHttpClient;
    }

    @GetMapping("/tier/types")
    public ResponseEntity<List<Map<String, Object>>> getTypeTiers() {
        log.info("GET /api/dux/tier/types");
        List<Map<String, Object>> result = new ArrayList<>();
        try {
            String responseBody = duxHttpClient.get(typeTierUrl);
            log.info("DUX API response for type tiers: {}", responseBody);
            if (responseBody != null && !responseBody.isBlank()) {
                JsonNode root = objectMapper.readTree(responseBody);
                JsonNode array = null;
                if (root.isArray()) {
                    array = root;
                } else if (root.isObject()) {
                    for (String key : new String[]{"data", "content", "results"}) {
                        if (root.has(key) && root.get(key).isArray()) {
                            array = root.get(key);
                            break;
                        }
                    }
                }

                if (array != null && array.isArray()) {
                    for (JsonNode item : array) {
                        String code = "";
                        if (item.has("idTypeTier") && !item.get("idTypeTier").isNull()) {
                            code = item.get("idTypeTier").asText().trim();
                        } else if (item.has("id") && !item.get("id").isNull()) {
                            code = item.get("id").asText().trim();
                        } else if (item.has("codeTypeTier") && !item.get("codeTypeTier").isNull()) {
                            code = item.get("codeTypeTier").asText().trim();
                        } else if (item.has("code") && !item.get("code").isNull()) {
                            code = item.get("code").asText().trim();
                        }

                        String libelle = "";
                        if (item.has("libelleTypeTier") && !item.get("libelleTypeTier").isNull()) {
                            libelle = item.get("libelleTypeTier").asText().trim();
                        } else if (item.has("libelle") && !item.get("libelle").isNull()) {
                            libelle = item.get("libelle").asText().trim();
                        } else if (item.has("codeTypeTier") && !item.get("codeTypeTier").isNull()) {
                            libelle = item.get("codeTypeTier").asText().trim();
                        } else {
                            libelle = code;
                        }

                        if (!code.isBlank()) {
                            Map<String, Object> map = new HashMap<>();
                            map.put("code", code);
                            map.put("libelle", libelle);
                            if (item.has("code") && !item.get("code").isNull()) {
                                map.put("typeCode", item.get("code").asText().trim());
                            } else if (item.has("codeTypeTier") && !item.get("codeTypeTier").isNull()) {
                                map.put("typeCode", item.get("codeTypeTier").asText().trim());
                            }
                            result.add(map);
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("Failed to fetch all tier types from DUX", e);
        }

        if (result.isEmpty()) {
            log.info("DUX API returned empty or unauthorized list of tier types. Returning fallback list.");
            result = getFallbackTypeTiers();
        }

        return ResponseEntity.ok(result);
    }

    private List<Map<String, Object>> getFallbackTypeTiers() {
        List<Map<String, Object>> fallback = new ArrayList<>();

        Map<String, Object> clt = new HashMap<>();
        clt.put("code", "1");
        clt.put("libelle", "Client");
        clt.put("typeCode", "clt");
        fallback.add(clt);

        Map<String, Object> pat = new HashMap<>();
        pat.put("code", "2");
        pat.put("libelle", "Patient");
        pat.put("typeCode", "pat");
        fallback.add(pat);

        Map<String, Object> proj = new HashMap<>();
        proj.put("code", "3");
        proj.put("libelle", "Projet");
        proj.put("typeCode", "Projet");
        fallback.add(proj);

        Map<String, Object> emp = new HashMap<>();
        emp.put("code", "4");
        emp.put("libelle", "Employé");
        emp.put("typeCode", "emp");
        fallback.add(emp);

        Map<String, Object> st = new HashMap<>();
        st.put("code", "5");
        st.put("libelle", "Sous-traitant");
        st.put("typeCode", "ST");
        fallback.add(st);

        return fallback;
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

    @GetMapping("/tier/findbycode/{code}")
    public ResponseEntity<String> findTierByCode(@PathVariable String code) {
        log.info("GET /api/dux/tier/findbycode/{}", code);
        String baseDuxUrl = typeTierUrl.split("/api/")[0];
        String url = baseDuxUrl + "/api/tier/findbycode/" + code;
        String result = duxHttpClient.get(url);
        return ResponseEntity.ok(result);
    }
}
