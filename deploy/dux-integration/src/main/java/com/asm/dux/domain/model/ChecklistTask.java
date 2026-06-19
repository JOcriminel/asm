package com.asm.dux.domain.model;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Table(name = "preparation_ChecklistTask")
public class ChecklistTask {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nomTache;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "type_id", nullable = false)
    private ChecklistTaskType type;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "group_id")
    private ChecklistGroup group;

    @Column(name = "codeFamille", nullable = true)
    private String codeFamille;

    @Column(nullable = false, columnDefinition = "bit default 1")
    private Boolean active = true;

    @Column(nullable = true, length = 1000)
    private String information;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNomTache() { return nomTache; }
    public void setNomTache(String nomTache) { this.nomTache = nomTache; }

    public ChecklistTaskType getType() { return type; }
    public void setType(ChecklistTaskType type) { this.type = type; }

    public ChecklistGroup getGroup() { return group; }
    public void setGroup(ChecklistGroup group) { this.group = group; }

    public String getCodeFamille() { return codeFamille; }
    public void setCodeFamille(String codeFamille) { this.codeFamille = codeFamille; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public String getInformation() { return information; }
    public void setInformation(String information) { this.information = information; }
}
