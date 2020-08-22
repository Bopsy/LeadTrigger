/*
 * Copyright (c) 2020. 7Summits Inc.
 */
public with sharing class x7s_Adventure_Response
{
    @AuraEnabled public Boolean success{get;set;} // success or failure
    @AuraEnabled public x7s_Adventure_Setting__mdt globalSetting{get;set;} // adventure setup
    @AuraEnabled public x7s_Adventure_MyProgress adventureProgress{get;set;} // filtered adventure Progress
    @AuraEnabled public List<String> messages{get;set;}  // messages to display
    @AuraEnabled public List<SObject> results{get;set;} // results to iterate over - use this when querying SOjbects directoy
    @AuraEnabled public List<x7s_Adventure_ContentObject> peakResults{get;set;} // custom results to iterate over - use this when creating a list of custom wrapper classes

    public x7s_Adventure_Response(){
        success = true;        
        messages = new List<String>();
        globalSetting = new x7s_Adventure_Setting__mdt();
        adventureProgress = new x7s_Adventure_MyProgress();
        results = new List<SObject>();        
        peakResults = new List<x7s_Adventure_ContentObject>();
    }
}