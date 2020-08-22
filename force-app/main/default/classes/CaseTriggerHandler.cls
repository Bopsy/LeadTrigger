/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           CaseTriggerHandler 
*
* @description    help class for CaseTrigger
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Mia Cui     <ncui@twilio.com>
* @modifiedBy     Mia Cui     <ncui@twilio.com>
* @version        1.0
* @created        2019-09-19
* @modified       2019-09-19
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes 
**/

public class CaseTriggerHandler {

    //Check if List_out_all_Account_SID_s_to_be_added__c field is changed or not
    public static void checkSID(Map<ID, Case> newMap, Map<ID, Case> oldMap){
        Case_Constants__c  comsData = Case_Constants__c.getInstance('COMS');

        List<Case> filterCase = new List<Case>();
        //ensure the triggre do not fire on old cases.
        date startDate = date.newInstance(2019, 9, 19);
        if(comsData != NULL) startDate = comsData.Trigger_Start_Date__c;

        for(ID caseID: newMap.keySet()) {
            if (newMap.get(caseID).createdDate > startDate 
                && (newMap.get(caseID).Primary_SID_on_Order_Form__c != oldMap.get(caseID).Primary_SID_on_Order_Form__c 
                || newMap.get(caseID).SIDs_to_add_to_Pricing_Model_if_needed__c != oldMap.get(caseID).SIDs_to_add_to_Pricing_Model_if_needed__c  
                || newMap.get(caseID).SIDS_to_add_to_Order_Form__c != oldMap.get(caseID).SIDS_to_add_to_Order_Form__c)  ){
                filterCase.add(newMap.get(caseID));
            }
        }
        if (filterCase.size() > 0) checkSID(filterCase);
    }
    
    //check if the Account SID belongs to Account
    public static void checkSID(List<Case> newCases){
        Case_Constants__c  comsData = Case_Constants__c.getInstance('COMS');
        List<ID> lstAccId = new List<ID>();
        List<Case> filterCase = new List<Case>();
        
        for(Case c: newCases) {
            if (c.RecordTypeId == comsData.Record_Type_ID__c  &&(c.Primary_SID_on_Order_Form__c != NULL 
                || c.SIDs_to_add_to_Pricing_Model_if_needed__c != NULL 
                || c.SIDS_to_add_to_Order_Form__c != NULL)) {
                filterCase.add(c);
                lstAccId.add(c.AccountID);
            }
        }
        
        if(filterCase.size() ==0) {
            System.debug('===> no case need to check yeah!!'); 
            return;
        }
        
        System.debug('start soql sid that belongs to each account');
        List<Account_SID__c> accSIDLibrary = [ SELECT name, Account__c, Account__r.name 
                                               FROM Account_SID__c 
                                               WHERE Account__c IN:lstAccId];
        
        Map<ID, List<String>> accToSIDMap = new Map<ID, List<String>>();
        Map<ID, String> accIdToAccName = new Map<ID, String>();
        
        for(Account_SID__c accSID: accSIDLibrary){
            accIdToAccName.put(accSID.Account__c, accSID.Account__r.name);
            if(accToSIDMap.get(accSID.Account__c) == NULL) {
                accToSIDMap.put(accSID.Account__c, new List<String>());
            }
            accToSIDMap.get(accSID.Account__c).add(accSID.name);
        }
        
        for(Case caseRec: filterCase) {
            String rawData1 = caseRec.Primary_SID_on_Order_Form__c;
            if (rawData1 != NULL) {
                List<String> lstAccSID = rawData1.split(',');

                for(String sid: lstAccSID) {
                    String sidWithoutSpace = sid.trim();//get rid of all spaces
                    if(accToSIDMap.get(caseRec.AccountId) == NULL || !accToSIDMap.get(caseRec.AccountId).contains(sidWithoutSpace)) {
                        caseRec.Primary_SID_on_Order_Form__c.addError(sidWithoutSpace + ' does not belong to this account: ' + accIdToAccName.get(caseRec.AccountId), false);
                        break;
                    }
                    
                }
            }
            
            String rawData2 = caseRec.SIDs_to_add_to_Pricing_Model_if_needed__c;
            if (rawData2 != NULL) {
                List<String> lstAccSID2 = rawData2.split(',');
                for(String sid: lstAccSID2) {
                    String sidWithoutSpace = sid.trim();//get rid of all spaces
                    if(accToSIDMap.get(caseRec.AccountId) == NULL || !accToSIDMap.get(caseRec.AccountId).contains(sidWithoutSpace)) {
                        caseRec.SIDs_to_add_to_Pricing_Model_if_needed__c.addError(sidWithoutSpace + ' does not belong to this account: ' + accIdToAccName.get(caseRec.AccountId), false);
                        break;
                    }
                    
                }
            }
            
            String rawData3 = caseRec.SIDS_to_add_to_Order_Form__c;
            if (rawData3 != NULL) {
                List<String> lstAccSID3 = rawData3.split(',');
                for(String sid: lstAccSID3) {
                    String sidWithoutSpace = sid.trim();//get rid of all spaces
                    if(accToSIDMap.get(caseRec.AccountId) == NULL || !accToSIDMap.get(caseRec.AccountId).contains(sidWithoutSpace)) {
                        caseRec.SIDS_to_add_to_Order_Form__c.addError(sidWithoutSpace + ' does not belong to this account: ' + accIdToAccName.get(caseRec.AccountId), false);
                        break;
                    }
                }
            }            
        }
    }
}