/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_AdventureDocLinkTriggerHandler {
    public static void handleBeforeInsert(List<ContentDocumentLink> newList){
        for(ContentDocumentLink contentLink : newList) {
            Schema.SObjectType sobjectType = contentLink.LinkedEntityId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();
            if(sobjectName == 'Adventure__c' || sobjectName == 'Adventure_Step__c' || sobjectName == 'Module_Task__c' || sobjectName == 'Step_Module__c'){
                contentLink.Visibility='AllUsers';
            }
        }
    }
}