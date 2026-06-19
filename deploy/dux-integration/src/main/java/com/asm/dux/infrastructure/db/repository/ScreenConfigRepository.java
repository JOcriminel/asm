package com.asm.dux.infrastructure.db.repository;

import com.asm.dux.domain.model.ScreenConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ScreenConfigRepository extends JpaRepository<ScreenConfig, String> {
}
