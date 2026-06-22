package com.asm.dux.domain.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Column;

@Entity
@Table(name = "dux_screen_configs")
public class ScreenConfig {

    @Id
    @Column(name = "document_type", length = 50)
    private String documentType;

    @Column(name = "page_title", length = 255)
    private String pageTitle;

    @Column(name = "search_hint", length = 255)
    private String searchHint;

    @Column(name = "enable_barcode_scanner")
    private Boolean enableBarcodeScanner = false;

    @Column(name = "enable_pdf_printing")
    private Boolean enablePdfPrinting = false;

    @Column(name = "enable_serial_number_tracking")
    private Boolean enableSerialNumberTracking = false;

    @Column(name = "enable_checklist_tracking")
    private Boolean enableChecklistTracking = false;

    @Column(name = "visible_roles", length = 2000)
    private String visibleRoles;

    @Column(name = "detail_page_title", length = 255)
    private String detailPageTitle;

    @Column(name = "hide_prices_for_operateurs")
    private Boolean hidePricesForOperateurs = false;

    @Column(name = "allowed_roles_to_finalize", length = 2000)
    private String allowedRolesToFinalize;

    @Column(name = "category", length = 100)
    private String category;

    @Column(name = "primary_color", length = 50)
    private String primaryColor;

    @Column(name = "require_signature")
    private Boolean requireSignature = false;

    @Column(name = "require_photo")
    private Boolean requirePhoto = false;

    @Column(name = "default_sort_field", length = 50)
    private String defaultSortField;

    @Column(name = "enable_sound_alerts")
    private Boolean enableSoundAlerts;

    @Column(name = "enable_vibration_alerts")
    private Boolean enableVibrationAlerts;

    @Column(name = "active")
    private Boolean active = true;

    @Column(name = "hide_prices")
    private Boolean hidePrices = false;

    @Column(name = "details_fields_config", length = 4000)
    private String detailsFieldsConfig;

    @Column(name = "card_fields_config", length = 1000)
    private String cardFieldsConfig;

    @Column(name = "search_fields_config", length = 1000)
    private String searchFieldsConfig;

    @Column(name = "custom_finalize_message", length = 2000)
    private String customFinalizeMessage;

    @Column(name = "hide_prices_for_roles", length = 2000)
    private String hidePricesForRoles;

    @Column(name = "status_filters", length = 1000)
    private String statusFilters;

    public ScreenConfig() {
    }

    public String getDocumentType() {
        return documentType;
    }

    public void setDocumentType(String documentType) {
        this.documentType = documentType;
    }

    public String getPageTitle() {
        return pageTitle;
    }

    public void setPageTitle(String pageTitle) {
        this.pageTitle = pageTitle;
    }

    public String getSearchHint() {
        return searchHint;
    }

    public void setSearchHint(String searchHint) {
        this.searchHint = searchHint;
    }

    public boolean isEnableBarcodeScanner() {
        return enableBarcodeScanner != null && enableBarcodeScanner;
    }

    public void setEnableBarcodeScanner(boolean enableBarcodeScanner) {
        this.enableBarcodeScanner = enableBarcodeScanner;
    }

    public boolean isEnablePdfPrinting() {
        return enablePdfPrinting != null && enablePdfPrinting;
    }

    public void setEnablePdfPrinting(boolean enablePdfPrinting) {
        this.enablePdfPrinting = enablePdfPrinting;
    }

    public boolean isEnableSerialNumberTracking() {
        return enableSerialNumberTracking != null && enableSerialNumberTracking;
    }

    public void setEnableSerialNumberTracking(boolean enableSerialNumberTracking) {
        this.enableSerialNumberTracking = enableSerialNumberTracking;
    }

    public boolean isEnableChecklistTracking() {
        return enableChecklistTracking != null && enableChecklistTracking;
    }

    public void setEnableChecklistTracking(boolean enableChecklistTracking) {
        this.enableChecklistTracking = enableChecklistTracking;
    }

    public String getVisibleRoles() {
        return visibleRoles;
    }

    public void setVisibleRoles(String visibleRoles) {
        this.visibleRoles = visibleRoles;
    }

    public String getDetailPageTitle() {
        return detailPageTitle;
    }

    public void setDetailPageTitle(String detailPageTitle) {
        this.detailPageTitle = detailPageTitle;
    }

    public boolean isHidePricesForOperateurs() {
        return hidePricesForOperateurs != null && hidePricesForOperateurs;
    }

    public void setHidePricesForOperateurs(boolean hidePricesForOperateurs) {
        this.hidePricesForOperateurs = hidePricesForOperateurs;
    }

    public boolean isHidePrices() {
        return hidePrices != null && hidePrices;
    }

    public void setHidePrices(boolean hidePrices) {
        this.hidePrices = hidePrices;
    }

    public String getAllowedRolesToFinalize() {
        return allowedRolesToFinalize;
    }

    public void setAllowedRolesToFinalize(String allowedRolesToFinalize) {
        this.allowedRolesToFinalize = allowedRolesToFinalize;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getPrimaryColor() {
        return primaryColor;
    }

    public void setPrimaryColor(String primaryColor) {
        this.primaryColor = primaryColor;
    }

    public boolean isRequireSignature() {
        return requireSignature != null && requireSignature;
    }

    public void setRequireSignature(boolean requireSignature) {
        this.requireSignature = requireSignature;
    }

    public boolean isRequirePhoto() {
        return requirePhoto != null && requirePhoto;
    }

    public void setRequirePhoto(boolean requirePhoto) {
        this.requirePhoto = requirePhoto;
    }

    public String getDefaultSortField() {
        return defaultSortField;
    }

    public void setDefaultSortField(String defaultSortField) {
        this.defaultSortField = defaultSortField;
    }

    public boolean isEnableSoundAlerts() {
        return enableSoundAlerts == null || enableSoundAlerts;
    }

    public void setEnableSoundAlerts(Boolean enableSoundAlerts) {
        this.enableSoundAlerts = enableSoundAlerts;
    }

    public boolean isEnableVibrationAlerts() {
        return enableVibrationAlerts == null || enableVibrationAlerts;
    }

    public void setEnableVibrationAlerts(Boolean enableVibrationAlerts) {
        this.enableVibrationAlerts = enableVibrationAlerts;
    }

    public Boolean getActive() {
        return active == null || active;
    }

    public void setActive(Boolean active) {
        this.active = active;
    }

    public String getDetailsFieldsConfig() {
        return detailsFieldsConfig;
    }

    public void setDetailsFieldsConfig(String detailsFieldsConfig) {
        this.detailsFieldsConfig = detailsFieldsConfig;
    }

    public String getCardFieldsConfig() {
        return cardFieldsConfig;
    }

    public void setCardFieldsConfig(String cardFieldsConfig) {
        this.cardFieldsConfig = cardFieldsConfig;
    }

    public String getSearchFieldsConfig() {
        return searchFieldsConfig;
    }

    public void setSearchFieldsConfig(String searchFieldsConfig) {
        this.searchFieldsConfig = searchFieldsConfig;
    }

    public String getCustomFinalizeMessage() {
        return customFinalizeMessage;
    }

    public void setCustomFinalizeMessage(String customFinalizeMessage) {
        this.customFinalizeMessage = customFinalizeMessage;
    }

    public String getHidePricesForRoles() {
        return hidePricesForRoles;
    }

    public void setHidePricesForRoles(String hidePricesForRoles) {
        this.hidePricesForRoles = hidePricesForRoles;
    }

    public String getStatusFilters() {
        return statusFilters;
    }

    public void setStatusFilters(String statusFilters) {
        this.statusFilters = statusFilters;
    }
}
