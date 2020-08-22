/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  EmailOptOutServices
*
* @description 	  Service class that contains methods that handle Email Opt Out cascading.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu	 <jayu@twilio.com>
* @version        1.0
* @created        2019-03-22
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public without sharing class EmailOptOutServices {
	//Depending on who creates the Contact, update the Third Party Data Source.  Third Party Data Source is consumed
    //by Eloqua.
    public static void checkThirdPartyDataSource(List<Contact> newConts){
        Boolean tpds = Third_Party_Data_Source__c.getInstance(UserInfo.getProfileId()).Third_Party_Data_Source__c;
        for(Contact contRec : newConts){
            if(contRec.Third_Party_Data_Source__c == false){ //Allow people to explicitly set this to TRUE.
            	contRec.Third_Party_Data_Source__c = tpds;    
            }
        }
    }
    
    //Check to see if existing Leads/Contacts with a matching email have Opted Out of Email Communications.  
    //If so, then also Opt Out this new Contact from Email Communications.
    public static void checkDuplicateRecordsForEmailOptOut(List<Contact> newConts){
        Set<String> uniqueEmails = new Set<String>();
        
        for(Contact cont : newConts){
            if(cont.Email != null){
                uniqueEmails.add(cont.Email);
            } else if (cont.Preferred_Email__c != null){
                uniqueEmails.add(cont.Preferred_Email__c);
            }
        }
        
        if(!uniqueEmails.isEmpty()){
            Map<String, Boolean> emailOptOutMap = new Map<String, Boolean>();
            List<Contact> contsWithEmailOptOut = new List<Contact>();
            List<Lead> leadsWithEmailOptOut = new List<Lead>();
            
            contsWithEmailOptOut = [SELECT Email, Preferred_Email__c, HasOptedOutOfEmail FROM Contact WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = TRUE];
            leadsWithEmailOptOut = [SELECT Email, HasOptedOutOfEmail FROM Lead WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = TRUE AND IsConverted = FALSE];
            
            if(!contsWithEmailOptOut.isEmpty()){
                for(Contact contRec: contsWithEmailOptOut){
                    emailOptOutMap.put(contRec.Email, contRec.HasOptedOutOfEmail);
                }
            }
            
            if(!leadsWithEmailOptOut.isEmpty()){
                for(Lead leadRec : leadsWithEmailOptOut){
                    emailOptOutMap.put(leadRec.Email, leadRec.HasOptedOutOfEmail);
                }
            }
            
            if(!emailOptOutMap.keySet().isEmpty()){
                for(Contact cont : newConts){
                    if(emailOptOutMap.get(cont.Email) != null){
                    	cont.HasOptedOutOfEmail = emailOptOutMap.get(cont.Email);    
                    }
                }
            }
        }
    }
    
    //When a Contact opts out of email communication.  Also opt out Contacts/Leads with a matching email address.
    public static void optOutDuplicateRecordsWithMatchingEmail(List<Contact> newConts, Map<Id, Contact> oldContMap){
        Set<String> uniqueEmails = new Set<String>();
        
        for(Contact cont : newConts){
            Contact oldCont = oldContMap.get(cont.Id);
            
            //Check to see if Contact has opted out of email.
            if(oldCont.HasOptedOutOfEmail == FALSE && cont.HasOptedOutOfEmail == TRUE){
                if(cont.Email != null){
                    uniqueEmails.add(cont.Email);
                } else if (cont.Preferred_Email__c != null){
                    uniqueEmails.add(cont.Preferred_Email__c);
                }
            }
        }
        
        if(!uniqueEmails.isEmpty()){
            List<Contact> contsToOptOut = [SELECT Id, Email FROM Contact WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = FALSE];
            List<Lead> leadsToOptOut = [SELECT Id, Email FROM Lead WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = FALSE AND IsConverted = FALSE];
            
            if(contsToOptOut != null){
                List<Contact> contsForUpdate = new List<Contact>();
                for(Contact contRec : contsToOptOut){
                    contRec.HasOptedOutOfEmail = TRUE;
                    contsForUpdate.add(contRec);
                }
                update contsForUpdate;
            }
            
            if(leadsToOptOut != null){
                List<Lead> leadsForUpdate = new List<Lead>();
                for(Lead leadRec : leadsToOptOut){
                    leadRec.HasOptedOutOfEmail = TRUE;
                    leadsForUpdate.add(leadRec);
                }
                update leadsForUpdate;
            }
        }
    }
    
    //Depending on who creates the Lead, update the Third Party Data Source.  Third Party Data Source is consumed
    //by Eloqua.
    public static void checkThirdPartyDataSource(List<Lead> newLeads){
        Boolean tpds = Third_Party_Data_Source__c.getInstance(UserInfo.getProfileId()).Third_Party_Data_Source__c;
        for(Lead leadRec : newLeads){
            if(leadRec.Third_Party_Data_Source__c == false){ //Allow people to explicitly set this to TRUE.
            	leadRec.Third_Party_Data_Source__c = tpds;
            }
        }
    }
    
    //Check to see if existing Leads/Contacts with a matching email have Opted Out of Email Communications.  
    //If so, then also Opt Out this new Contact from Email Communications.
    public static void checkDuplicateRecordsForEmailOptOut(List<Lead> newLeads){
        Set<String> uniqueEmails = new Set<String>();
        for(Lead leadRec : newLeads){
            if(leadRec.Email != null){
                uniqueEmails.add(leadRec.Email);
            } else if (leadRec.Preferred_Email__c != null){
                uniqueEmails.add(leadRec.Preferred_Email__c);
            }
        }
        
        if(!uniqueEmails.isEmpty()){
            Map<String, Boolean> emailOptOutMap = new Map<String, Boolean>();
            List<Contact> contsWithEmailOptOut = new List<Contact>();
            List<Lead> leadsWithEmailOptOut = new List<Lead>();
            
            contsWithEmailOptOut = [SELECT Email, Preferred_Email__c, HasOptedOutOfEmail FROM Contact WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = TRUE];
            leadsWithEmailOptOut = [SELECT Email, HasOptedOutOfEmail FROM Lead WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = TRUE AND IsConverted = FALSE];
            
            if(!contsWithEmailOptOut.isEmpty()){
                for(Contact contRec: contsWithEmailOptOut){
                    emailOptOutMap.put(contRec.Email, contRec.HasOptedOutOfEmail);
                }
            }
            
            if(!leadsWithEmailOptOut.isEmpty()){
                for(Lead leadRec : leadsWithEmailOptOut){
                    emailOptOutMap.put(leadRec.Email, leadRec.HasOptedOutOfEmail);
                }
            }
            
            if(!emailOptOutMap.keySet().isEmpty()){
                for(Lead leadRec : newLeads){
                    if(emailOptOutMap.get(leadRec.Email) != null){
                    	leadRec.HasOptedOutOfEmail = emailOptOutMap.get(leadRec.Email);    
                    }
                }
            }
        }
    }
    
    //When a Lead opts out of email communication.  Also opt out Contacts/Leads with a matching email address.
    public static void optOutDuplicateRecordsWithMatchingEmail(List<Lead> newLeads, Map<Id, Lead> oldLeadMap){
        Set<String> uniqueEmails = new Set<String>();
        
        for(Lead leadRec : newLeads){
            Lead oldLead = oldLeadMap.get(leadRec.Id);
            
            //Check to see if Contact has opted out of email.
            if(oldLead.HasOptedOutOfEmail == FALSE && leadRec.HasOptedOutOfEmail == TRUE){
                if(leadRec.Email != null){
                    uniqueEmails.add(leadRec.Email);
                } else if (leadRec.Preferred_Email__c != null){
                    uniqueEmails.add(leadRec.Preferred_Email__c);
                }
            }
        }
        
        if(!uniqueEmails.isEmpty()){
            List<Contact> contsToOptOut = [SELECT Id, Email FROM Contact WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = FALSE];
            List<Lead> leadsToOptOut = [SELECT Id, Email FROM Lead WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = FALSE AND IsConverted = FALSE];
            
            if(contsToOptOut != null){
                List<Contact> contsForUpdate = new List<Contact>();
                for(Contact contRec : contsToOptOut){
                    contRec.HasOptedOutOfEmail = TRUE;
                    contsForUpdate.add(contRec);
                }
                update contsForUpdate;
            }
            
            if(leadsToOptOut != null){
                List<Lead> leadsForUpdate = new List<Lead>();
                for(Lead leadRec : leadsToOptOut){
                    leadRec.HasOptedOutOfEmail = TRUE;
                    leadsForUpdate.add(leadRec);
                }
                update leadsForUpdate;
            }
        }
    }
    
    //Return a Set of Emails based on the Leads passed.
    public static Set<String> getEmailSet(List<Lead> leadRecs){
        Set<String> emailSet = new Set<String>();
        
        for(Lead leadRec : leadRecs){
            emailSet.add(leadRec.Email);
        }
        
        return emailSet;
    }
    
    //Return a Set of Emails based on the Contacts passed.
    public static Set<String> getEmailSet(List<Contact> contRecs){
        Set<String> emailSet = new Set<String>();
        
        for(Contact contRec : contRecs){
            emailSet.add(contRec.Email);
        }
        
        return emailSet;
    }
    
    //Return a list of Leads for Email Opt Out.
    public static List<Lead> getLeadsForEmailOptOut(Set<String> uniqueEmails){
        List<Lead> leadsForEmailOptOut = new List<Lead>();
        List<Lead> leadsForReview = [SELECT Id FROM Lead WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = FALSE AND IsConverted = FALSE];
        
        if(leadsForReview != null){
            for(Lead leadRec : leadsForReview){
                leadRec.HasOptedOutOfEmail = TRUE;
                leadsForEmailOptOut.add(leadRec);
            }    
        }
        
        return leadsForEmailOptOut;
    }
    
    //Return a list of Contacts for Email Opt Out.
    public static List<Contact> getContactsForEmailOptOut(Set<String> uniqueEmails){
        List<Contact> contsForEmailOptOut = new List<Contact>();
        List<Contact> contsForReview = [SELECT Id FROM Contact WHERE Email IN :uniqueEmails AND HasOptedOutOfEmail = FALSE];
        
        if(contsForReview != null){
            for(Contact contRec : contsForReview){
                contRec.HasOptedOutOfEmail = TRUE;
                contsForEmailOptOut.add(contRec);
            }    
        }
        
        return contsForEmailOptOut;
    }
}