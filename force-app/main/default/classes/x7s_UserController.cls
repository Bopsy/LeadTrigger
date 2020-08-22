/*
 * Class Name : x7s_UserController
 * Description : updates the proceed verified field on user record of current user
 * Created By : Dhana Prasad (10-04-2020)
 * Last Modified by :
 * Copyrights @ 7summits 2020
*/ 
public with sharing class x7s_UserController {
    /*Method Name : changeProceedToVerify
     * Description : updates the proceed verified field on user record of current user
     * Created by : Dhana Prasad (10-04-2020)
    */
    @AuraEnabled
    public static void changeProceedToVerify(boolean proceedToVerify){
        User currentUser = [SELECT Id, Proceed_Verified__c FROM User
                           WHERE Id =: UserInfo.getUserId()];
        if(proceedToVerify){
          currentUser.Proceed_Verified__c = proceedToVerify;
            update currentUser;
        }
        
    }
    /*Method Name : getProceedToVerify
     * Description : retrieves the proceed verified field on user record of current user
     * Created by : Ben Logan (10-04-2020)
    */
    @AuraEnabled
    public static boolean getProceedToVerify(){
        boolean proceedToVerify = true;
        User currentUser = [SELECT Id, Proceed_Verified__c FROM User
                           WHERE Id =: UserInfo.getUserId()];
        if(currentUser.Proceed_Verified__c!=null){
            proceedToVerify=currentUser.Proceed_Verified__c;
        }                  
        return proceedToVerify;
        
    }

}