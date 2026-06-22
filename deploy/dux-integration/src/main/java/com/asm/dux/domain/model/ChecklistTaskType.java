package com.asm.dux.domain.model;

import jakarta.persistence.*;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@Entity
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
@Table(name = "preparation_ChecklistTaskType")
public class ChecklistTaskType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String name;

    @Column(nullable = true, length = 1000)
    private String information;

    @Column(nullable = false, columnDefinition = "bit default 1")
    private boolean active = true;

    @Column(name = "code_doc", nullable = true, length = 50)
    private String codeDoc;

    @Column(name = "roles", nullable = true, length = 500)
    private String roles;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getInformation() { return information; }
    public void setInformation(String information) { this.information = information; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public String getCodeDoc() { return codeDoc; }
    public void setCodeDoc(String codeDoc) { this.codeDoc = codeDoc; }

    public String getRoles() { return roles; }
    public void setRoles(String roles) { this.roles = roles; }
}
