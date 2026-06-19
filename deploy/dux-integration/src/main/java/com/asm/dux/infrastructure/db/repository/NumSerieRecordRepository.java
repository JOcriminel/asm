package com.asm.dux.infrastructure.db.repository;

import com.asm.dux.infrastructure.db.entity.NumSerieRecord;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NumSerieRecordRepository extends JpaRepository<NumSerieRecord, Long> {
    List<NumSerieRecord> findByNumSerieIgnoreCase(String numSerie);
    boolean existsByNumSerieIgnoreCase(String numSerie);
}
