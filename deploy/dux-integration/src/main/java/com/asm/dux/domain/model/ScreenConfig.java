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
    private boolean enableBarcodeScanner;

    @Column(name = "enable_pdf_printing")
    private boolean enablePdfPrinting;

    @Column(name = "enable_serial_number_tracking")
    private boolean enableSerialNumberTracking;

    @Column(name = "visible_roles", length = 2000)
    private String visibleRoles;

    @Column(name = "detail_page_title", length = 255)
    private String detailPageTitle;

    @Column(name = "hide_prices_for_operateurs")
    private boolean hidePricesForOperateurs;

    @Column(name = "allowed_roles_to_finalize", length = 2000)
    private String allowedRolesToFinalize;

    @Column(name = "primary_color", length = 50)
    private String primaryColor;

    @Column(name = "require_signature")
    private boolean requireSignature;

    @Column(name = "require_photo")
    private boolean requirePhoto;

    @Column(name = "default_sort_field", length = 50)
    private String defaultSortField;

    @Column(name = "enable_sound_alerts")
    private Boolean enableSoundAlerts;

    @Column(name = "enable_vibration_alerts")
    private Boolean enableVibrationAlerts;

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
        return enableBarcodeScanner;
    }

    public void setEnableBarcodeScanner(boolean enableBarcodeScanner) {
        this.enableBarcodeScanner = enableBarcodeScanner;
    }

    public boolean isEnablePdfPrinting() {
        return enablePdfPrinting;
    }

    public void setEnablePdfPrinting(boolean enablePdfPrinting) {
        this.enablePdfPrinting = enablePdfPrinting;
    }

    public boolean isEnableSerialNumberTracking() {
        return enableSerialNumberTracking;
    }

    public void setEnableSerialNumberTracking(boolean enableSerialNumberTracking) {
        this.enableSerialNumberTracking = enableSerialNumberTracking;
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
        return hidePricesForOperateurs;
    }

    public void setHidePricesForOperateurs(boolean hidePricesForOperateurs) {
        this.hidePricesForOperateurs = hidePricesForOperateurs;
    }

    public String getAllowedRolesToFinalize() {
        return allowedRolesToFinalize;
    }

    public void setAllowedRolesToFinalize(String allowedRolesToFinalize) {
        this.allowedRolesToFinalize = allowedRolesToFinalize;
    }

    public String getPrimaryColor() {
        return primaryColor;
    }

    public void setPrimaryColor(String primaryColor) {
        this.primaryColor = primaryColor;
    }

    public boolean isRequireSignature() {
        return requireSignature;
    }

    public void setRequireSignature(boolean requireSignature) {
        this.requireSignature = requireSignature;
    }

    public boolean isRequirePhoto() {
        return requirePhoto;
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
}
