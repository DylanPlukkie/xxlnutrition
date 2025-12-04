/**
 * @description Service class for handling Contact upsert operations from Exact integration
 * @author Dylan Pluk
 * @date 2024-12-04
 */
public with sharing class ExactContactService {
    
    /**
     * @description Upserts a Contact based on Exact ID and links it to an Account
     * If Contact exists with the given Exact ID, it will be updated
     * If Contact does not exist, a new Contact will be created
     * If AccountExactId is provided, the Contact will be linked to the corresponding Account
     * @param request ExactContactRequest containing contact data from Exact
     * @return Contact The upserted Contact record
     * @throws ExactIntegrationException if Account lookup or DML operations fail
     */
    public Contact upsertContactByExactId(ExactContactRequest request) {
        Contact existingContact = findContactByExactId(request.ExactId);
        String accountId = findAccountIdByExactId(request.AccountExactId);
        
        if (existingContact != null) {
            return updateExistingContact(existingContact, request, accountId);
        } else {
            return createNewContact(request, accountId);
        }
    }
    
    /**
     * @description Finds a Contact by exactId__c field
     * @param exactId The Exact ID to search for
     * @return Contact The found Contact record, or null if not found
     */
    private Contact findContactByExactId(String exactId) {
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, AccountId
            FROM Contact
            WHERE exactId__c = :exactId
            LIMIT 1
        ];
        
        return contacts.isEmpty() ? null : contacts[0];
    }
    
    /**
     * @description Finds an Account ID by querying the Exact_Account_Id__c child object
     * @param accountExactId The Account Exact ID to search for
     * @return String The Account ID, or null if accountExactId is blank
     * @throws ExactIntegrationException if accountExactId is provided but Account is not found
     */
    private String findAccountIdByExactId(String accountExactId) {
        if (String.isBlank(accountExactId)) {
            return null;
        }
        
        List<Exact_Account_Id__c> exactAccountIds = [
            SELECT Account__c
            FROM Exact_Account_Id__c
            WHERE Exact_Id__c = :accountExactId
            LIMIT 1
        ];
        
        if (exactAccountIds.isEmpty()) {
            throw new ExactIntegrationException('Account with Exact ID ' + accountExactId + ' not found');
        }
        
        return exactAccountIds[0].Account__c;
    }
    
    /**
     * @description Updates an existing Contact with data from the request
     * @param existingContact The Contact record to update
     * @param request ExactContactRequest containing the new data
     * @param accountId The Account ID to link the Contact to (can be null)
     * @return Contact The updated Contact record
     * @throws ExactIntegrationException if the update operation fails
     */
    private Contact updateExistingContact(Contact existingContact, ExactContactRequest request, String accountId) {
        mapRequestToContact(existingContact, request, accountId);
        
        try {
            update existingContact;
            return existingContact;
        } catch (DmlException e) {
            throw new ExactIntegrationException('Failed to update contact: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a new Contact with data from the request
     * @param request ExactContactRequest containing the contact data
     * @param accountId The Account ID to link the Contact to (can be null)
     * @return Contact The newly created Contact record
     * @throws ExactIntegrationException if the create operation fails
     */
    private Contact createNewContact(ExactContactRequest request, String accountId) {
        Contact newContact = new Contact();
        mapRequestToContact(newContact, request, accountId);
        newContact.exactId__c = request.ExactId;
        
        try {
            insert newContact;
            return newContact;
        } catch (DmlException e) {
            throw new ExactIntegrationException('Failed to create contact: ' + e.getMessage());
        }
    }
    
    /**
     * @description Maps data from ExactContactRequest to Contact record
     * @param cont The Contact record to populate
     * @param request ExactContactRequest containing the source data
     * @param accountId The Account ID to link the Contact to (can be null)
     */
    private void mapRequestToContact(Contact cont, ExactContactRequest request, String accountId) {
        cont.AccountId = accountId;
        cont.FirstName = request.FirstName;
        cont.LastName = request.LastName;
        cont.Email = request.Email;
        cont.MobilePhone = request.MobilePhone;
        cont.OtherPhone = request.OtherPhone;
    }
}