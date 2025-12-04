/**
 * @description Data Transfer Object (DTO) for Account data from Exact integration
 * Contains all fields that can be sent in the API request for Account upsert
 * @author Dylan Pluk
 * @date 2024-12-04
 */
public class ExactAccountRequest {
    /** @description Exact system unique identifier for the account */
    public String ExactId { get; set; }
    
    /** @description Account name */
    public String Name { get; set; }
    
    /** @description Status of the account in Exact system */
    public String ExactStatus { get; set; }
    
    /** @description Chamber of Commerce number */
    public String COCNumber { get; set; }
    
    /** @description VAT (Value Added Tax) number */
    public String VATNumber { get; set; }
    
    /** @description Billing street address */
    public String BillingStreet { get; set; }
    
    /** @description Billing city */
    public String BillingCity { get; set; }
    
    /** @description Billing state/province */
    public String BillingState { get; set; }
    
    /** @description Billing postal code */
    public String BillingPostalCode { get; set; }
    
    /** @description Billing country */
    public String BillingCountry { get; set; }
    
    /** @description Shipping street address */
    public String ShippingStreet { get; set; }
    
    /** @description Shipping city */
    public String ShippingCity { get; set; }
    
    /** @description Shipping state/province */
    public String ShippingState { get; set; }
    
    /** @description Shipping postal code */
    public String ShippingPostalCode { get; set; }
    
    /** @description Shipping country */
    public String ShippingCountry { get; set; }
}