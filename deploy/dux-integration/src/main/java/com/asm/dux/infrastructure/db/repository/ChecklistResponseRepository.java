package com.asm.dux.infrastructure.db.repository;

import com.asm.dux.domain.model.ChecklistResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public interface ChecklistResponseRepository extends JpaRepository<ChecklistResponse, Long> {
    List<ChecklistResponse> findByIdLigneDocument(String idLigneDocument);
    Optional<ChecklistResponse> findByIdLigneDocumentAndTaskId(String idLigneDocument, Long taskId);
    void deleteByIdLigneDocument(String idLigneDocument);
    long countByIsCheckedTrueAndDateCheckedBetween(LocalDateTime start, LocalDateTime end);

    @Query("SELECT HOUR(r.dateChecked) as hour, COUNT(r) as count " +
           "FROM ChecklistResponse r " +
           "WHERE r.isChecked = true AND r.dateChecked BETWEEN :startDate AND :endDate " +
           "GROUP BY HOUR(r.dateChecked) " +
           "ORDER BY hour ASC")
    List<Map<String, Object>> countChecklistsGroupedByHour(
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT CAST(r.dateChecked AS date) as date, COUNT(r) as count " +
           "FROM ChecklistResponse r " +
           "WHERE r.isChecked = true AND r.dateChecked BETWEEN :startDate AND :endDate " +
           "GROUP BY CAST(r.dateChecked AS date) " +
           "ORDER BY date ASC")
    List<Map<String, Object>> countChecklistsGroupedByDay(
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT YEAR(r.dateChecked) as year, MONTH(r.dateChecked) as month, COUNT(r) as count " +
           "FROM ChecklistResponse r " +
           "WHERE r.isChecked = true AND r.dateChecked BETWEEN :startDate AND :endDate " +
           "GROUP BY YEAR(r.dateChecked), MONTH(r.dateChecked) " +
           "ORDER BY year ASC, month ASC")
    List<Map<String, Object>> countChecklistsGroupedByMonth(
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );

    @Query("SELECT r.checkedBy as userId, COUNT(r) as count " +
           "FROM ChecklistResponse r " +
           "WHERE r.isChecked = true AND r.dateChecked BETWEEN :startDate AND :endDate " +
           "GROUP BY r.checkedBy")
    List<Map<String, Object>> getOperatorChecklistsCount(
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate
    );
}
