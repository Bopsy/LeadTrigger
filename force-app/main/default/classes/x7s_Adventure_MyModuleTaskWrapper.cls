/*
 * Copyright (c) 2020. 7Summits Inc.
 */

public with sharing class x7s_Adventure_MyModuleTaskWrapper {
   
    @AuraEnabled public Decimal TaskProgress{get;set;}
    @AuraEnabled public Boolean Completed{get;set;}
        
}