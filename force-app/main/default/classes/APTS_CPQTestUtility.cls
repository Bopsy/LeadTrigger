/**
 * This apex class provides methods to create test data for Apttus CPQ flow.
 * Created By - Mausam Padhiyar
 * Created Date - 21st March, 2017
 */
public class APTS_CPQTestUtility {
    
    /*
     * Create Test Account
     */
    public static Account createAccount(String strName, String strType) {
        Account testAccount = new Account();
        testAccount.Name = strName;
        testAccount.Type = strType;
        
        return testAccount;
        
    }
    
    /*
     * Create Test Contact
     */
    public static Contact createContact(String strLastName, String strAccountId) {
        Contact testContact = new Contact();
        testContact.LastName = strLastName;
        testContact.AccountId = strAccountId;
        
        return testContact;
        
    }
    
    /*
     * Create Test Opportunity
     */
    public static Opportunity createOpportunity(String strName, String strType, Id accountId, String strStageName) {
        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = strName;
        testOpportunity.Type = strType;
        testOpportunity.AccountId = accountId;
        testOpportunity.StageName = strStageName;
        testOpportunity.CloseDate = date.Today().addDays(365);
        
        return testOpportunity;
    }
    
    /*
     * Create Price List
     */
    public static Apttus_Config2__PriceList__c createPriceList(String strName, Boolean bIsActive) {
        Apttus_Config2__PriceList__c priceList = new Apttus_Config2__PriceList__c();
        priceList.Name = strName;
        priceList.Apttus_Config2__Active__c = bIsActive;
        
        return priceList;
    }
    
    /*
     * Create  Product
     */
    public static Product2 createProduct(String productName, String productCode, String productFamily, String strConifgurationType, Boolean bCustomizable, Boolean bHasOptions, Boolean bHasAttributes, Boolean bIsActive) {
        Product2 product = new Product2();
        product.Name = productName;
        product.ProductCode = productCode;
        product.Family = productFamily;
        product.Apttus_Config2__ConfigurationType__c = strConifgurationType;
        product.Apttus_Config2__Customizable__c = bCustomizable;
        product.Apttus_Config2__HasOptions__c = bHasOptions;
        product.Apttus_Config2__HasAttributes__c = bHasAttributes;
        product.IsActive = bIsActive;
        
        return product; 
    }
     
    /*
     * Create Price List Item
     */
    public static Apttus_Config2__PriceListItem__c createPriceListItem(Id priceListId, Id productId, decimal dListPrice, String strChargeType, String strPriceType, String strPriceMethod, String strPriceUoM, Boolean bIsActive) {
        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c();
        pli.Apttus_Config2__PriceListId__c = priceListId;
        pli.Apttus_Config2__ProductId__c = productId;
        pli.Apttus_Config2__ListPrice__c = dListPrice;
        pli.Apttus_Config2__ChargeType__c = strChargeType;
        pli.Apttus_Config2__PriceType__c = strPriceType;
        pli.Apttus_Config2__PriceMethod__c = strPriceMethod;
        pli.Apttus_Config2__PriceUom__c = strPriceUoM;
        pli.Apttus_Config2__Active__c = bIsActive;
                
        return pli;
    }
    
    /*
     * Create Proposal
     */
    public static Apttus_Proposal__Proposal__c createProposal( String quoteName, ID accId, ID optyId, String recordTypeName, ID priceList){
        
        Apttus_Proposal__Proposal__c proposal = new Apttus_Proposal__Proposal__c();
        proposal.Apttus_Proposal__Proposal_Name__c = quoteName;
        proposal.Apttus_Proposal__Opportunity__c = optyId;
        proposal.Apttus_Proposal__Account__c = accId;
        proposal.RecordTypeId = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        proposal.Apttus_QPConfig__PriceListId__c = priceList;
        
        return proposal;
    }
    
    /*
     * Create Configuration
     */
    public static String createConfiguration(String strProposalId) {
        Apttus_CPQApi.CPQ.CreateCartRequestDO request = new Apttus_CPQApi.CPQ.CreateCartRequestDO();
        request.QuoteId = strProposalId;
        Apttus_CPQApi.CPQ.CreateCartResponseDO response = Apttus_CPQApi.CPQWebService.createCart(request);
        return response.CartId; 
    }
    

    
    /*
     *  Create Line Item (Max 32 param limit exceeded)
     */
    public static void createLineItem(Id cartId, Id productId, Integer iQty){
        
        Apttus_CPQApi.CPQ.SelectedProductDO selProdDO = new Apttus_CPQApi.CPQ.SelectedProductDO();
        selProdDO.ProductID = productId;
        selProdDO.Quantity = iQty;
        
        Apttus_CPQApi.CPQ.AddMultiProductRequestDO requestBundle = new Apttus_CPQApi.CPQ.AddMultiProductRequestDO ();
        requestBundle.CartId = cartId;
        requestBundle.SelectedProducts = new List<Apttus_CPQApi.CPQ.SelectedProductDO>{selProdDO};
        Apttus_CPQApi.CPQ.AddMultiProductResponseDO response = Apttus_CPQApi.CPQWebService.addMultiProducts(requestBundle);
    }
    
    
}