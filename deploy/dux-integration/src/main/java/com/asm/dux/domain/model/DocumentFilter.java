package com.asm.dux.domain.model;

/**
 * Domain value object carrying all filter parameters for the command-list query.
 * Pure Java record — no Spring or HTTP dependencies.
 *
 * @param from         start date (yyyy-MM-dd)
 * @param to           end date (yyyy-MM-dd HH:mm:ss)
 * @param idTier       client/tier identifier or "all"
 * @param repres       representative identifier or "all"
 * @param codeDoc      document class code (e.g. "BCC")
 * @param idEtat       status identifier or "all"
 * @param all          include deleted/archived flag
 * @param allDocuments include all document types
 * @param idArticle    article filter or "null"
 * @param affichAvanc  advanced filter flag
 * @param stationId    optional station filter (null = no filter)
 */
public record DocumentFilter(
        String from,
        String to,
        String idTier,
        String repres,
        String codeDoc,
        String idEtat,
        String all,
        String allDocuments,
        String idArticle,
        String affichAvanc,
        String stationId
) {}
