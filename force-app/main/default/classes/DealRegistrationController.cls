public without sharing class DealRegistrationController {
    
    @AuraEnabled
    public static String saveLeadDetails(string strLead, string mainWrap, List<string> mpicklist){
        System.debug('mpicklist***'+mpicklist);
        System.debug('strLead***'+strLead);
        System.debug('mainWrap***'+mainWrap);
        
        mainWrapper objMainWrap;
        String returnId='';
       try{
            if((strLead != null && strLead != '') && (mainWrap != null && mainWrap != '')){
                objMainWrap = (mainWrapper)JSON.deserialize(mainWrap, mainWrapper.class);
                Pass_to_Partner__c theLead = (Pass_to_Partner__c)JSON.deserialize(strLead, Pass_to_Partner__c.class); 
                System.debug('theLead***'+theLead);
                //if(objMainWrap.strCNOfEmp == '1-99') theLead.NumberOfEmployees = 50;
                //if(objMainWrap.strCNOfEmp == '100-1,999') theLead.NumberOfEmployees = 1000;
                //if(objMainWrap.strCNOfEmp == '2,000-9,999') theLead.NumberOfEmployees = 5000;
                //if(objMainWrap.strCNOfEmp == '10,000+') theLead.NumberOfEmployees = 10001;
                //theLead.Employee_Size__c = objMainWrap.strCNOfEmp;
                //theLead.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();
                Id partnerAccountId = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Contact.AccountId;
                theLead.Partner_Account__c = partnerAccountId;
                theLead.Type__c = 'SI';
                theLead.Stage__c = 'Deal Reg Pending';
                theLead.Name = 'Test';
                List<Contact> relatedContacts = [SELECT Id FROM Contact WHERE Email = :theLead.Contact_Email_Text__c];
                if(relatedContacts.size() > 0){
                    theLead.Contact__c = relatedContacts[0].Id;
                }
                else{
                    List<String> emails = theLead.Contact_Email_Text__c.split('@');
                    if(emails.size() > 1){
                        String domain = emails[1];
                        List<Email_Domain__c> domains = [SELECT Account__c FROM Email_Domain__c WHERE Name = :domain];
                        Id accountId = null;
                        if(domains.size() > 0){
                            accountId = domains[0].Account__c;
                        }
                        else{
                            Account newAcc = new Account(Name = theLead.Company_Name__c, BillingCountry = 'United States', BillingPostalCode = theLead.Customer_Headquarters_Zip_Code__c, Employee_Size__c = objMainWrap.strCNOfEmp);
                            insert newAcc;
                            accountId = newAcc.Id;
                            Set<String> freeDomains = new Set<String>();
                            for(String emailString: Free_Email_Domains__c.getAll().keySet()){
                                freeDomains.add(emailString);
                            }
                            if(!freeDomains.contains(domain)){
                                insert new Email_Domain__c(Approved__c = true, Name = domain, Account__c = accountId);
                            }
                        }
                        List<String> fullName = theLead.Contact_Name_Text__c.split(' ');
                        Contact newContact = new Contact(AccountId = accountId, FirstName = fullName.size() > 1 ? fullName[0] : null, LastName = fullName.size() > 1 ? fullName[1] : fullName[0], Email = theLead.Contact_Email_Text__c, Title = theLead.Customer_Title__c);
                        insert newContact;
                        theLead.Contact__c = newContact.Id;
                    }
                }
                //theLead.FY_16_Primary_Product_Input__c = objMainWrap.lstofSelectedMultiPV[0];
                //theLead.LastName = theLead.Company;
                Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Partner_to_Twilio' LIMIT 1].Id;
                theLead.RecordTypeId = recordTypeId;
                insert theLead;
                System.debug('theLead***'+theLead.Id);
                returnId= theLead.Id;
            } 
           return returnId;
        }catch(Exception ex){
            System.debug('Error in:::'+ex.getLineNumber()+' and exception:::'+ex.getMessage());
           return null;
       }
       
    }
    
    @AuraEnabled
    public static string onloadLead(){
        mainWrapper objwrap = new mainWrapper();
        objwrap.objLead = new Pass_to_Partner__c();
        try{    
            List<String> optionsLeadPN = new List<String>();
           
            
            List<String> optionsLeadCNOfEmp = new List<String>();
            Schema.DescribeFieldResult fieldResultLeadCNOfEmp = Lead.NumberOfEmployees.getDescribe();
            List<Schema.PicklistEntry> pListLeadCNOfEmp = fieldResultLeadCNOfEmp.getPicklistValues();
            for (Schema.PicklistEntry p01: pListLeadCNOfEmp) {
                optionsLeadCNOfEmp.add(p01.getLabel());
            }
            objwrap.lstCNOfEmp = optionsLeadCNOfEmp;
            
            List<String> plValues = new List<String>();
            Schema.SObjectType objType = Schema.getGlobalDescribe().get('Opportunity');
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe(); 
            Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get('FY_16_Primary_Product__c').getDescribe();
            List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
            for(Schema.PicklistEntry plv: picklistvalues) {
                plValues.add(plv.getValue());
            }
            //plValues.sort();
            objwrap.lstofMultiPV = plValues;
            
            
        }catch(exception e){          
        }
        System.debug('====' +Json.serialize(objWrap));
        return Json.serialize(objWrap);
        //return null;
    }
    
    public class mainWrapper{    
        @AuraEnabled
        public Pass_to_Partner__c objLead{get;set;}
        
        @AuraEnabled
        public list<string> lstPartnerName{get;set;}
        @AuraEnabled
        public string strPartnerName{get;set;}
        
        @AuraEnabled
        public list<string> lstCNOfEmp{get;set;}
        @AuraEnabled
        public string strCNOfEmp{get;set;}
        
        @AuraEnabled
        public list<string> lstofMultiPV{get;set;}
        @AuraEnabled
        public list<string> lstofSelectedMultiPV{get;set;}
    }
    
}