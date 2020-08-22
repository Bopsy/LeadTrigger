public with sharing class BatchAccountSIDServices {
    
    public static void rollupNPC(List<Account_SID__c> accountSids){
        Set<Id> accountIds = new Set<Id>();
        for(Account_SID__c accountSid: accountSids){
            accountIds.add(accountSid.Account__c);
        }
        Map<Id, Account> accountMaps = new Map<Id,Account>([SELECT First_NPC_5_Date__c, First_NPC_50_Date__c, First_NPC_500_Date__c, First_Account_SID_Created_Date__c 
                                                            FROM Account 
                                                            WHERE Id =: accountIds]);
        List<Account> updateAccounts = new List<Account>();
        for(Account_SID__c accountSid: accountSids){
            if(accountMaps.containsKey(accountSid.Account__c)){
                Account acc = accountMaps.get(accountSid.Account__c);
                acc.First_NPC_5_Date__c = minDate(acc.First_NPC_5_Date__c, accountSid.NPC_Date_5__c);
                acc.First_NPC_50_Date__c = minDate(acc.First_NPC_50_Date__c, accountSid.NPC_Date_50__c);
                acc.First_NPC_500_Date__c = minDate(acc.First_NPC_500_Date__c, accountSid.NPC_Date_500__c);
                acc.First_Account_SID_Created_Date__c = minDate(acc.First_Account_SID_Created_Date__c, accountSid.Account_SID_Created_Date__c);
            }
        }
        update accountMaps.values();
    }
    
    public static void rollupTwilioOrgData(List<Account> accounts){
        List<Account_SID__c> accountSIDs = [SELECT Account__c, Twilio_org_Pricing_Model__c, Invoicing__c FROM Account_SID__c WHERE Account__c =: accounts];
        
        Map<Id, List<Account_SID__c>> accountToSidMap = new Map<Id, List<Account_SID__c>>();
        
        for(Account_SID__c sid: accountSIDs){
            List<Account_SID__c> sids = accountToSidMap.get(sid.Account__c);
            if(sids == null || sids.isEmpty()){
                sids = new List<Account_SID__c>();
            }
            sids.add(sid);
            accountToSidMap.put(sid.Account__c, sids);
        }
        
        for(Account acc: accounts){
            acc.Number_of_Account_SIDs__c = 0; 
            acc.Number_of_Twilio_org_Account_SIDs__c = 0;
            acc.Number_of_Invoiced_Account_SIDs__c = 0;
            List<Account_SID__c> sids = accountToSidMap.get(acc.Id);
            if(sids != null && !sids.isEmpty()){
                for(Account_SID__c accountSid:sids){
                    acc.Number_of_Account_SIDs__c ++;	
                    if(accountSid.Twilio_org_Pricing_Model__c == true){
                         acc.Number_of_Twilio_org_Account_SIDs__c++;
                    }
                    if(accountSid.Invoicing__c == true){
                        acc.Number_of_Invoiced_Account_SIDs__c++;
                    }
                }
            }
        }
        Database.update(accounts, false);
    }
    
    @TestVisible
    private static Date minDate(Date date1, Date date2){
        if(date1 == null) return date2;
        if(date2 == null) return date1;
        return Date1 < Date2 ? Date1 : Date2;
    }
    
    //Added By Amrutha - method to rollup(Count) SendGrid Accounts related to a Account
    public static void rollupSendGrid(List<Account> lstAccount){
        List<Account> updateAccounts = new List<Account>();
        if(lstAccount.size()>0){
            /*for(Account objAcc: [SELECT Id, Number_of_SendGrid_Accounts__c,SendGrid_Major_Account__c,SendGrid_Portfolio_Account__c,  
                                         (SELECT Id,Account__c, SendGrid_CSM_Id__c, Invoice_Total_Last_Month__c, Major_Account__c,Portfolio_Account__c FROM SendGrid_Accounts__r ORDER BY MRR__c DESC NULLS LAST)
                                 FROM Account
                                 WHERE Id =:lstAccount]){
                
                objAcc.Number_of_SendGrid_Accounts__c = objAcc.SendGrid_Accounts__r.size();
                objAcc.Total_SendGrid_Invoice_Amount_Last_Month__c = 0;
                objAcc.SendGrid_Major_Account__c=false;
                objAcc.SendGrid_Portfolio_Account__c=false;
                objAcc.SendGrid_CSM__c = null;
                if(objAcc.SendGrid_Accounts__r.size()>0){
                    for(SendGrid_Account__c objSendgrid: objAcc.SendGrid_Accounts__r){
                        if(objSendgrid.SendGrid_CSM_Id__c != null && objAcc.SendGrid_CSM__c == null && objSendgrid.SendGrid_CSM_Id__c != 'Integration User'){
                            objAcc.SendGrid_CSM__c = objSendGrid.SendGrid_CSM_Id__c;
                        }
                        if(objSendgrid.Major_Account__c ==true){
                            objAcc.SendGrid_Major_Account__c=true;
                        }
                        if(objSendgrid.Portfolio_Account__c ==true){
                            objAcc.SendGrid_Portfolio_Account__c=true;
                        }
                        if(objSendgrid.Invoice_Total_Last_Month__c != null){objAcc.Total_SendGrid_Invoice_Amount_Last_Month__c += objSendgrid.Invoice_Total_Last_Month__c;}
                        if(objAcc.SendGrid_Major_Account__c && objAcc.SendGrid_Portfolio_Account__c) break;
                    }
                }
                updateAccounts.add(objAcc);
            }*/
            Map<Id,List<SendGrid_Account__c>> mapAccIdWithSGAccs = new Map<Id,List<SendGrid_Account__c>>();
            List<SendGrid_Account__c> lstSGAcc = [Select Id,Account__c, SendGrid_CSM_Id__c, Invoice_Total_Last_Month__c, Major_Account__c,Portfolio_Account__c FROM 
                                              	  SendGrid_Account__c where Account__c IN: lstAccount ORDER BY MRR__c DESC NULLS LAST];
            
            for(SendGrid_Account__c objSGAcc : lstSGAcc) {
                if(mapAccIdWithSGAccs.containsKey(objSGAcc.Account__c)) {
                    List<SendGrid_Account__c> lstSG = mapAccIdWithSGAccs.get(objSGAcc.Account__c);
                    lstSG.add(objSGAcc);
                    mapAccIdWithSGAccs.put(objSGAcc.Account__c, lstSG);
                } else {
                    mapAccIdWithSGAccs.put(objSGAcc.Account__c, new List<SendGrid_Account__c> { objSGAcc });
                }
            }
            
            for(Account objAcc: [SELECT Id, Number_of_SendGrid_Accounts__c,SendGrid_Major_Account__c,SendGrid_Portfolio_Account__c FROM Account
                                   WHERE Id =:lstAccount]){
                
                objAcc.Number_of_SendGrid_Accounts__c = mapAccIdWithSGAccs.get(objAcc.Id).size();
                objAcc.Total_SendGrid_Invoice_Amount_Last_Month__c = 0;
                objAcc.SendGrid_Major_Account__c=false;
                objAcc.SendGrid_Portfolio_Account__c=false;
                //objAcc.SendGrid_CSM__c = null;
                if(mapAccIdWithSGAccs.get(objAcc.Id).size()>0){
                    for(SendGrid_Account__c objSendgrid: mapAccIdWithSGAccs.get(objAcc.Id)){
                        //if(objSendgrid.SendGrid_CSM_Id__c != null && objAcc.SendGrid_CSM__c == null && objSendgrid.SendGrid_CSM_Id__c != 'Integration User'){
                        //    objAcc.SendGrid_CSM__c = objSendGrid.SendGrid_CSM_Id__c;
                        //}
                        if(objSendgrid.Major_Account__c ==true){
                            objAcc.SendGrid_Major_Account__c=true;
                        }
                        if(objSendgrid.Portfolio_Account__c ==true){
                            objAcc.SendGrid_Portfolio_Account__c=true;
                        }
                        if(objSendgrid.Invoice_Total_Last_Month__c != null){objAcc.Total_SendGrid_Invoice_Amount_Last_Month__c += objSendgrid.Invoice_Total_Last_Month__c;}
                        if(objAcc.SendGrid_Major_Account__c && objAcc.SendGrid_Portfolio_Account__c) break;
                    }
                }
                updateAccounts.add(objAcc);
            }
        }
        system.debug('+++updateAccounts '+updateAccounts);
        Database.update(updateAccounts, false);
    }
}