package com.asm.dux.domain.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;

@Entity
@Table(name = "dux_categories")
public class Category {

    @Id
    @Column(name = "name", length = 100)
    private String name;

    @Column(nullable = false, columnDefinition = "bit default 1")
    private boolean active = true;

    public Category() {
    }

    public Category(String name) {
        this.name = name;
        this.active = true;
    }

    public Category(String name, boolean active) {
        this.name = name;
        this.active = active;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}
