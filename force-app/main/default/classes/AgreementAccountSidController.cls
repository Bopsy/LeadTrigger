public without sharing class AgreementAccountSidController {

    // instance variable for the standard controller
    private ApexPages.StandardController controller {get; set;}

    private Integer maxSearchResults = 50; 

    private String baseQuery() {
        return 'SELECT Id, '
            + '  Account_SID__r.Id, '
            + '  Account_SID__r.Name, '
            + '  Account_SID__r.Software_MRR__c, '
            + '  Account_SID__r.Total_MRR__c, '
            + '  Account_SID__r.New_Business_Opportunity__c, '
            + '  Account_SID__r.Exception_Opportunity__c, '
            + '  Account_SID__r.NPC_Date_50__c, '
            + '  Account_SID__r.Account_SID_Created_Date__c, '
            + '  Account_SID__r.Account_SID_Status__c, '
            + '  Account_SID__r.Account_SID_Type__c, '
            + '  Account_SID__r.Account__r.Id '
            + 'FROM Opp_SID_SKUs__r '
            + 'WHERE IsDeleted = false ';
    }

    public Apttus__APTS_Agreement__c agreement {get;set;}
    public Id oppId {get;set;}

    public Boolean hasOppSidSkus {
        get { return !searchResults.IsEmpty(); }
        set;
    }
    public Boolean hasPrimarySID {
        get { return !String.IsBlank(agreement.Primary_Account_SID__c); }
        set;
    }
    public Boolean hasFlexSID {
        get { return !String.IsBlank(agreement.Flex_Account_SID__c); }
        set;
    }
    
    // the results from the search. do not init the results or a blank rows show up initially on page load
    public List<AccountSID> searchResults {get;set;}
    public String totalRecordsFound {get;set;}

    // properties holding the selected account SID information
    public String accountSID {get;set;}
    public String recordID {get;set;}
    public String linkAs {get;set;}
    public String sidStatus {get;set;}

    public List<Agreement_SID__c> existingAgreementSkus {get; set;}

    // the soql without the order and limit
    private String soql {get;set;}

    // the soql with criteria, order, and limit
    private String fullQuery {get;set;}

    public AgreementAccountSidController() { 
        System.debug('AgreementAccountSidController()');

        searchResults = new List<AccountSID>();

        String aggrementId = Apexpages.currentPage().getParameters().get('id');
        this.agreement = initializeAgreement(aggrementId);
        this.oppId = this.agreement.Related_Opportunity_APTS__c;
        initializeOppty(oppId);
    }

    public AgreementAccountSidController(ApexPages.StandardController controller) {
        System.debug('AgreementAccountSidController(controller) - controller =  ' + controller);

        //initialize the standard controller
        this.controller = controller;

        // Need to add all of the fields so that they will be needed from the Opportunity
        List<String> fieldList = new List<String>();
        fieldList.add('Related_Opportunity_APTS__c');
        fieldList.add('Primary_Account_SID__c');
        fieldList.add('Flex_Account_SID__c');
        fieldList.add('Additional_Account_SIDs__c');
        if (!Test.isRunningTest()) {
            controller.addFields(fieldList);
        }
        this.agreement = (Apttus__APTS_Agreement__c)controller.getRecord();
        this.oppId = this.agreement.Related_Opportunity_APTS__c;

        searchResults = new List<AccountSID>();
        initializeOppty(this.oppId);
    }
    
    // Initialize the agreement
    private Apttus__APTS_Agreement__c initializeAgreement(Id agreementId) {
        List<Apttus__APTS_Agreement__c> a = [
            SELECT Id, Related_Opportunity_APTS__c, Primary_Account_SID__c, Flex_Account_SID__c, Additional_Account_SIDs__c, Payment_Type__c 
            FROM Apttus__APTS_Agreement__c
            WHERE Id = :agreementId
        ];
        if (a.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - Agreement not found having that record ID.'));
            return null;
        } else {
            return a[0];
        }
    }

    // Initialize the opportunity and its properties
    // If an error occurs "false" will be returned otherwise "true"
    private Boolean initializeOppty(Opportunity o) {
        System.debug('AgreementAccountSidController.initializeOppty(o) - o = ' + o);

        existingAgreementSkus = [
            SELECT Id,
                Is_Primary_Account_SID__c,
                Is_Flex_Account_SID__c,
                Account_SID__r.Id,
                Account_SID__r.Name,
                Account_SID__r.Software_MRR__c,
                Account_SID__r.Total_MRR__c,
                Account_SID__r.New_Business_Opportunity__c,
                Account_SID__r.Exception_Opportunity__c,
                Account_SID__r.NPC_Date_50__c,
                Account_SID__r.Account_SID_Created_Date__c,
                Account_SID__r.Account_SID_Status__c,
                Account_SID__r.Account_SID_Type__c,
                Account_SID__r.Account__r.Id
            FROM Agreement_SID__c
            WHERE Agreement__r.Related_Opportunity_APTS__c = :o.Id and Agreement__r.Id= :this.agreement.Id
        ];
        
        // Reorder the list of existing SKUs so the Primary is first
        // and the Flex is second.
        Agreement_SID__c primaryActionSID, flexActionSID;
        for (Integer i = 0; i < existingAgreementSkus.size(); i++) {
            if (existingAgreementSkus[i].Is_Primary_Account_SID__c) {
                primaryActionSID = existingAgreementSkus.remove(i);
                break;
            }
        }
        for (Integer i = 0; i < existingAgreementSkus.size(); i++) {
            if (existingAgreementSkus[i].Is_Flex_Account_SID__c) {
                flexActionSID = existingAgreementSkus.remove(i);
                break;
            }
        }

        if (flexActionSID != null) {
            if (existingAgreementSkus.IsEmpty())
                existingAgreementSkus.add(flexActionSID);
            else
                existingAgreementSkus.add(0, flexActionSID);
        }
        if (primaryActionSID != null) {
            if (existingAgreementSkus.IsEmpty())
                existingAgreementSkus.add(primaryActionSID);
            else
                existingAgreementSkus.add(0, primaryActionSID);
        }
        
        runSearch();

        return true;
    }

    // If an error occurs "false" will be returned otherwise "true"
    private Boolean initializeOppty(Id oppId) {
        System.debug('AgreementAccountSidController.initializeOppty(Id) - oppId = ' + oppId);

        List<Opportunity> opp = [
            SELECT Id
            FROM Opportunity
            WHERE Id = :oppId
        ];
        if (opp.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - Opportunity not found having that record ID.'));
            return false;
        } else {
            this.oppId = oppId;
            return initializeOppty(opp[0]);
        }
    }
    
    // the text in the search box
    public string searchText {
        get { return (searchText == null) ? '' : searchText; }
        set;
    }
    
    public string sortField {
        get { return (sortField == null) ? 'Account_SID__r.Account_SID_Created_Date__c' : sortField; }
        set;
    }
    
    public string sortDir {
        get { return (sortDir == null) ? 'desc' : sortDir; }
        set;
    }

    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
        // run the query again
        runQuery();
    }
    // runs the actual query
    public void runQuery() {
        System.debug('AgreementAccountSidController.runQuery()');

        try {
            Set<Id> existingId = new Set<Id>();
            for(Agreement_SID__c sku: existingAgreementSkus){
                existingId.add(sku.Account_SID__c);
            }

            fullQuery = 'SELECT Id, (' 
                + soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults)
                + ') FROM Opportunity WHERE Id = :oppId';
            
            List <Opportunity> sidResults = Database.query(fullQuery);

            // If no results then return
            if (sidResults.isEmpty()) {
                return;
            }

            if (searchResults == null) {
                searchResults = new List<AccountSID>(); // init the list if it is null
            } else {
                searchResults.clear(); // clear out the current results if they exist
            }

            for (Opp_SID_SKU__c sku : sidResults[0].Opp_SID_SKUs__r) {
                System.debug(sku);
                AccountSID result = new AccountSID(
                    existingId.contains(sku.Account_SID__r.Id),
                    sku.Account_SID__r.Id,
                    sku.Account_SID__r.Name,
                    sku.Account_SID__r.Software_MRR__c,
                    sku.Account_SID__r.Total_MRR__c,
                    sku.Account_SID__r.New_Business_Opportunity__c,
                    sku.Account_SID__r.Exception_Opportunity__c,
                    sku.Account_SID__r.NPC_Date_50__c,
                    sku.Account_SID__r.Account_SID_Created_Date__c,
                    sku.Account_SID__r.Account_SID_Status__c,
                    sku.Account_SID__r.Account_SID_Type__c,
                    sku.Account_SID__r.Account__r.Id,
                    ''
                );
                searchResults.add(result);
            }
            System.debug('AgreementAccountSidController.runQuery(): searchResults.size() = ' + searchResults.size());

            if (searchResults.size() == 0) {
                totalRecordsFound = 'No matches';
            } else if (searchResults.size() == 1) {
                totalRecordsFound = '1 match found';
            } else if (searchResults.size() == maxSearchResults) {
                totalRecordsFound = String.valueOf(searchResults.size()) + '+ matches found (showing only ' + String.valueOf(maxSearchResults) + ')';
            } else if (searchResults.size() > 1) {
                totalRecordsFound = String.valueOf(searchResults.size()) + ' matches found';
            }

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - ' + e.getMessage()));
        }
    }

    // fired when the search button is clicked
    public PageReference runSearch() {
        String searchText = Apexpages.currentPage().getParameters().get('searchText');
        System.debug('AgreementAccountSidController.runSearch(): searchText = ' + searchText);
    
        soql = baseQuery();
        if (!String.isBlank(searchText))
            soql += ' AND Account_SID__r.Name = :searchText';

        // run the query again
        runQuery();

        return null;
    }
    
    // handle the action of the commandlink
    public PageReference link() {
        Apttus__APTS_Agreement__c objAgrt = [Select Id,Payment_Type__c from Apttus__APTS_Agreement__c where id=:this.agreement.Id Limit 1];
        String userProfile = [Select Id,Name from Profile where Id=:userinfo.getProfileId()].Name;
        List<String> lstProfiles = new List<String>();
        for(Profiles_link_trial_account__c setting: Profiles_link_trial_account__c.getAll().values()){
                lstProfiles.add(setting.name);
        }
        if(sidStatus=='TRIAL' && !lstProfiles.contains(userProfile) && objAgrt.Payment_Type__c=='Credit Card'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please activate Trial account before linking it to OF'));
            return null;
        }
        if(sidStatus=='SUSPENDED' && !lstProfiles.contains(userProfile)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please connect with Billing Team to unsuspend this accountsid before linking it to OF'));
            return null;
        }
        
        System.debug('AgreementAccountSidController.save() - accountSID: ' + accountSID);
        System.debug('AgreementAccountSidController.save() - recordSID: ' + recordID);
        System.debug('AgreementAccountSidController.save() - linkAs: ' + linkAs);
        System.debug('AgreementAccountSidController.save() - agreement: ' + agreement.Id);
        
        
        try {
            Agreement_SID__c agreementSID = new Agreement_SID__c(Agreement__c = this.agreement.Id, Account_SID__c = recordID);
            insert agreementSID;
            
            if (linkAs == 'Primary') {
                System.debug('AgreementAccountSidController.unlink() - Linking Primary SID: ' + accountSID + ' (' + recordID + ')');
                
                // Delete the old primary so it can be replaced
                if (agreement.Primary_Account_SID__c != null) {
                    for (Agreement_SID__c a : existingAgreementSkus) {
                        if (a.Account_SID__r.Name == agreement.Primary_Account_SID__c) {
                            delete new Agreement_SID__c(Id = a.Id);
                            break;
                        }
                    }
                }
                
                agreement.Primary_Account_SID__c = accountSID;
            } else if (linkAs == 'Flex') {
                System.debug('AgreementAccountSidController.unlink() - Linking Flex SID: ' + accountSID + ' (' + recordID + ')');
                agreement.Flex_Account_SID__c = accountSID;
            } else {
                System.debug('AgreementAccountSidController.unlink() - Linking Additional SID: ' + accountSID + ' (' + recordID + ')');
                List<String> sidList = new List<String>();
                for (Agreement_SID__c a : [
                    SELECT Account_SID__r.Name, Agreement__r.Primary_Account_SID__c, Agreement__r.Flex_Account_SID__c
                    FROM Agreement_SID__c
                    WHERE Agreement__c = :agreement.Id
                    ORDER BY Account_SID__r.Name
                ]) {
                    if (a.Account_SID__r.Name != a.Agreement__r.Primary_Account_SID__c && a.Account_SID__r.Name != a.Agreement__r.Flex_Account_SID__c) {
                        sidList.add(a.Account_SID__r.Name);
                    }
                }
                agreement.Additional_Account_SIDs__c = sidList.IsEmpty() ? null : String.join(sidList, ', ');
                //System.debug('AgreementAccountSidController.unlink() - Updated Additional Account SIDs: ' + agreement.Additional_Account_SIDs__c);
            }
            System.debug('AgreementAccountSidController.save() - Updated agreement: ' + agreement);
            if(sidStatus!=null){
                if(!(sidStatus.equalsIgnoreCase('ACTIVE'))){
                    agreement.Is_Trial_Closed_Account__c=true;
                }
            }
            update agreement;

            this.agreement = initializeAgreement(this.agreement.Id);
            initializeOppty(this.oppId);
        } catch (System.DMLException e) {
            ApexPages.addMessages(e);
        }
        
        return null;
    }

    // handle the action of the commandlink
    public PageReference unlink() {
        System.debug('AgreementAccountSidController.unlink() - accountSID: ' + accountSID);
        System.debug('AgreementAccountSidController.unlink() - recordSID: ' + recordID);
        System.debug('AgreementAccountSidController.unlink() - agreement: ' + agreement.Id);
        
        try {
            Agreement_SID__c agreementSID = new Agreement_SID__c(Id = recordID);
            delete agreementSID;
    
            if (accountSID == agreement.Primary_Account_SID__c) {
                System.debug('AgreementAccountSidController.unlink() - Unlinking Primary SID: ' + accountSID + ' (' + recordID + ')');
                agreement.Primary_Account_SID__c = null;
            } else if (accountSID == agreement.Flex_Account_SID__c) {
                System.debug('AgreementAccountSidController.unlink() - Unlinking Flex SID: ' + accountSID + ' (' + recordID + ')');
                agreement.Flex_Account_SID__c = null;
            } else {
                System.debug('AgreementAccountSidController.unlink() - Unlinking Additional SID: ' + accountSID + ' (' + recordID + ')');
                List<String> sidList = new List<String>();
                for (Agreement_SID__c a : [
                    SELECT Account_SID__r.Name, Agreement__r.Primary_Account_SID__c, Agreement__r.Flex_Account_SID__c
                    FROM Agreement_SID__c
                    WHERE Agreement__c = :agreement.Id
                    ORDER BY Account_SID__r.Name
                ]) {
                    if (a.Account_SID__r.Name != a.Agreement__r.Primary_Account_SID__c && a.Account_SID__r.Name != a.Agreement__r.Flex_Account_SID__c) {
                        sidList.add(a.Account_SID__r.Name);
                    }
                }
                agreement.Additional_Account_SIDs__c = sidList.IsEmpty() ? null : String.join(sidList, ', ');
                //System.debug('AgreementAccountSidController.unlink() - Updated Additional Account SIDs: ' + agreement.Additional_Account_SIDs__c);
            }
            update agreement;

            this.agreement = initializeAgreement(this.agreement.Id);
            initializeOppty(this.oppId);
        } catch (System.DMLException e) {
            ApexPages.addMessages(e);
        }
        
        return null;
    }


  // format the soql for display on the visualforce page
  public String debugSoql {
    get { return fullQuery; }
    set;
  }
  
  // format the parameters for display on the visualforce page
  public String debugParameters {
    get { return String.join(Apexpages.currentPage().getParameters().values(), ','); }
    set;
  }
  
  public class AccountSID {
    public Boolean existed {get; set;}

    public Id Account_SID_Id {get;set;}
    public String sidType {get; set;}
    public String Account_SID_Name {get; set;}
    public Decimal Software_MRR {get; set;}
    public Decimal Total_MRR {get; set;}
    public Id New_Business_Opportunity {get; set;}
    public Id Exception_Opportunity {get; set;}
    public Date NPC_Date_50 {get; set;}
    public Date Account_SID_Created_Date {get; set;}
    public String Account_SID_Status {get; set;}
    public String Account_SID_Type {get; set;}
    public Id Account_Id {get; set;}
    
    public AccountSID(
        Boolean existed,
        Id Account_SID_Id,
        String Account_SID_Name,
        Decimal Software_MRR,
        Decimal Total_MRR,
        Id New_Business_Opportunity_Id,
        Id Exception_Opportunity_Id,
        Date NPC_Date_50,
        Date Account_SID_Created_Date,
        String Account_SID_Status,
        String Account_SID_Type,
        Id Account_Id,
        String sidType
    ) {
        this.existed = existed;
        this.Account_SID_Id = Account_SID_Id;
        this.Account_SID_Name = Account_SID_Name;
        this.Software_MRR = Software_MRR;
        this.Total_MRR = Total_MRR;
        this.New_Business_Opportunity = New_Business_Opportunity;
        this.Exception_Opportunity = Exception_Opportunity;
        this.NPC_Date_50 = NPC_Date_50;
        this.Account_SID_Created_Date = Account_SID_Created_Date;
        this.Account_SID_Status = Account_SID_Status;
        this.Account_SID_Type = Account_SID_Type;
        this.Account_Id = Account_Id;
        this.sidType = sidType;
    }
  }
}