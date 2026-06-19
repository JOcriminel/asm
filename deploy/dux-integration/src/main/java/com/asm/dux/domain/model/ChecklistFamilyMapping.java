package com.asm.dux.domain.model;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Table(name = "preparation_ChecklistFamilyMapping")
public class ChecklistFamilyMapping {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String codeFamille;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id", nullable = false)
    private ChecklistGroup group;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCodeFamille() { return codeFamille; }
    public void setCodeFamille(String codeFamille) { this.codeFamille = codeFamille; }

    public ChecklistGroup getGroup() { return group; }
    public void setGroup(ChecklistGroup group) { this.group = group; }
}
