/**
 * @description Data Transfer Object (DTO) for Contact data from Exact integration
 * Contains all fields that can be sent in the API request for Contact upsert
 * @author Dylan Pluk
 * @date 2024-12-04
 */
public class ExactContactRequest {
    /** @description Exact system unique identifier for the contact */
    public String ExactId { get; set; }
    
    /** @description Exact system identifier for the related account */
    public String AccountExactId { get; set; }
    
    /** @description Contact's first name */
    public String FirstName { get; set; }
    
    /** @description Contact's last name */
    public String LastName { get; set; }
    
    /** @description Contact's email address */
    public String Email { get; set; }
    
    /** @description Contact's mobile phone number */
    public String MobilePhone { get; set; }
    
    /** @description Contact's other/alternative phone number */
    public String OtherPhone { get; set; }
}