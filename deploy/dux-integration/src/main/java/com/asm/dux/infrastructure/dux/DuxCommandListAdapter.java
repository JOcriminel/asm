package com.asm.dux.infrastructure.dux;

import com.asm.dux.domain.model.DocumentFilter;
import com.asm.dux.domain.port.CommandListGateway;
import com.asm.dux.exception.GatewayException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Infrastructure adapter: implements {@link CommandListGateway}.
 *
 * Responsibilities (each extracted as a private method — Single Responsibility):
 *   1. buildUrl()      — constructs the upstream DUX URL from filter parameters.
 *   2. filterByStation() — applies optional station-ID filtering to the response array.
 *   3. projectFields()  — projects each record to only the fields required by the frontend.
 *   4. replaceArray()   — replaces the array in the root JSON node.
 */
@Slf4j
@Component
public class DuxCommandListAdapter implements CommandListGateway {

    private final DuxHttpClient httpClient;
    private final ObjectMapper objectMapper;

    @Value("${dux.details-doc-url}")
    private String detailsDocUrl;

    public DuxCommandListAdapter(DuxHttpClient httpClient) {
        this.httpClient = httpClient;
        this.objectMapper = new ObjectMapper();
    }

    @Override
    public String getCommandList(DocumentFilter filter, String requestBody) {
        String url = buildUrl(filter);
        String responseBody = httpClient.post(url, requestBody);

        if (responseBody == null || responseBody.isBlank()) {
            return responseBody;
        }

        try {
            JsonNode root = objectMapper.readTree(responseBody);
            JsonNode dataNode = extractArray(root);

            if (dataNode == null || !dataNode.isArray()) {
                return responseBody;
            }

            ArrayNode filtered = filterByStation(dataNode, filter.stationId());
            ArrayNode projected = projectFields(filtered);

            return replaceArray(root, projected);

        } catch (Exception e) {
            log.error("Failed to parse or process command list response: {}", e.getMessage());
            throw new GatewayException("Failed to process command list response", e);
        }
    }

    // ─── Private helper methods ───────────────────────────────────────────────

    private String buildUrl(DocumentFilter f) {
        // Match the exact DUX ERP web client URL format:
        // /DetailsDoc2/{from}/{to}/{idTier}/{repres}/{codeDoc}/{idEtat}/{all}/{allDocuments}/{idArticle}/{affichAvanc}
        return detailsDocUrl
                + f.from() + "/" + f.to() + "/"
                + f.idTier() + "/" + f.repres() + "/"
                + f.codeDoc() + "/" + f.idEtat() + "/"
                + f.all() + "/" + f.allDocuments() + "/"
                + f.idArticle() + "/" + f.affichAvanc();
    }

    private JsonNode extractArray(JsonNode root) {
        if (root.isArray()) return root;
        if (root.isObject()) {
            for (String key : new String[]{"data", "content", "results", "documents"}) {
                if (root.has(key) && root.get(key).isArray()) {
                    return root.get(key);
                }
            }
        }
        return null;
    }

    private ArrayNode filterByStation(JsonNode array, String stationId) {
        ArrayNode result = objectMapper.createArrayNode();
        boolean applyFilter = stationId != null
                && !stationId.isBlank()
                && !"Default Station".equals(stationId);

        for (JsonNode item : array) {
            if (!applyFilter || matchesStation(item, stationId)) {
                result.add(item);
            }
        }
        return result;
    }

    private boolean matchesStation(JsonNode item, String stationId) {
        String idStation     = textOrEmpty(item, "idStation");
        String libelleStation = textOrEmpty(item, "libelleStation");
        String altStation    = textOrEmpty(item, "stationName");
        return idStation.equals(stationId)
                || libelleStation.equals(stationId)
                || altStation.equals(stationId);
    }

    private ArrayNode projectFields(ArrayNode source) {
        ArrayNode result = objectMapper.createArrayNode();
        for (JsonNode item : source) {
            result.add(projectItem(item));
        }
        return result;
    }

    private ObjectNode projectItem(JsonNode item) {
        ObjectNode out = objectMapper.createObjectNode();
        copyFirstPresent(item, out, "id", "idDoc");
        copyFirstPresent(item, out, "code", "documentCode", "codeDoc", "numDoc");
        copyFirstPresent(item, out, "dateDocument", "dateCreation");
        copyFirstPresent(item, out, "libelleClasseDocument", "documentType", "titreImprimable");
        copyIfPresent(item, out, "libelleEtatDoc", "couleurEtatDoc",
                "idStation", "libelleStation",
                "nomPrenomTier", "mntNetht", "mntTtc", "mntTva", "reste",
                "idTier", "nomPrenomRep", "symbole", "codeDev", "isVente",
                "dateValidation", "dateLivraison", "codeClasseDocument",
                "adresseTier", "telTier", "RepDoc");
        return out;
    }

    private void copyFirstPresent(JsonNode src, ObjectNode dst, String... keys) {
        for (String key : keys) {
            if (src.has(key) && !src.get(key).isNull()) {
                dst.set(key, src.get(key));
                return;
            }
        }
    }

    private void copyIfPresent(JsonNode src, ObjectNode dst, String... keys) {
        for (String key : keys) {
            if (src.has(key)) {
                dst.set(key, src.get(key));
            }
        }
    }

    private String textOrEmpty(JsonNode node, String field) {
        return node.has(field) && !node.get(field).isNull()
                ? node.get(field).asText() : "";
    }

    private String replaceArray(JsonNode root, ArrayNode newArray) throws Exception {
        if (root.isArray()) {
            return objectMapper.writeValueAsString(newArray);
        }
        ObjectNode obj = (ObjectNode) root;
        for (String key : new String[]{"data", "content", "results", "documents"}) {
            if (obj.has(key)) {
                obj.set(key, newArray);
                return objectMapper.writeValueAsString(obj);
            }
        }
        return objectMapper.writeValueAsString(newArray);
    }
}
