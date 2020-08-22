/*
 * Copyright (c) 2020. 7Summits Inc.
 */
public with sharing class x7s_Adventure_CloneProjectAssignment {
   
    // Clone the Selected adventure
    @AuraEnabled
    public static Id cloneAdventure(Id selectedAdventureId) {
        
        ID clonedAdventureId =null;
        clonedAdventureId= cloneAdventureWithAccount(selectedAdventureId,null);
        // try{
            
        //     Map<Adventure_Step__c,Adventure_Step__c> stepsParentChildMap = new Map<Adventure_Step__c,Adventure_Step__c>();
        //     Map<Module_Task__c,Module_Task__c> tasksParentChildMap = new Map<Module_Task__c,Module_Task__c>();
        //     Map<String,String> docFileMap ;
        //     Map<Id,List<ContentDocumentLink>> TasksDocumentLinkMap = new Map<Id,List<ContentDocumentLink>>();
        //     Map<Id,List<Module_Task__c>> moduleTasksMap = new Map<Id,List<Module_Task__c>>();
        //     Map<Step_Module__c,List<Module_Task__c>> masterFilesTasksMap = new  Map<Step_Module__c,List<Module_Task__c>>();
        //     Map<Adventure_Step__c,List<Step_Module__c>> cloneStepModuleMap =new Map<Adventure_Step__c,List<Step_Module__c>>();
        //     Map<Step_Module__c,List<Module_Task__c>> cloneModuleTaskMap = new Map<Step_Module__c,List<Module_Task__c>>();      
        //     List<Adventure_Step__c> clonedStepsList = new List<Adventure_Step__c>();
        //     List<Step_Module__c> clonedStepModuleList = new List<Step_Module__c>();
        //     List<Module_Task__c> clonedModuleTasksList = new List<Module_Task__c>();
        //     List<ContentDocumentLink> clonedTasksContectDocLinkList = new List<ContentDocumentLink>();
        //     List<ContentDocument> clonedTaskContentdocList = new List<ContentDocument>();
        //     Integer fileCounts =0;
            

        //     // Adventure creation
        //     if (selectedAdventureId !=null){
        //         //System.debug('Selected Record Id:'+ selectedAdventureId);
        //         Adventure__c cloneAdventure = [SELECT Id,Name,Title__c,Header_Image__c,Active__c,Banner_Image__c,Description__c,
        //         Source_Template__c,Subtitle__c,Title_Image__c,Completed__c,Account__c,Template__c,Adventure_Setting__c, Show_Checkboxes__c 
        //         FROM Adventure__c WHERE Id =:selectedAdventureId LIMIT 1];

                
        //         If(cloneAdventure != null){
                
        //             Adventure__c newAdventure = cloneAdventure.clone(false,true);
        //             if(newAdventure !=null){
        //                 newAdventure.Source_Template__c = cloneAdventure.Id;
        //                 newAdventure.Account__c = null;
        //                 newAdventure.Template__c = false;
        //                 newAdventure.Completed__c = false;
        //                 newAdventure.Name = cloneAdventure.Name + ' Copy';
        //                 insert newAdventure;
        //                 //Check & clone files if there is any in adventure
                       
        //                 clonedAdventureId = newAdventure.Id; 

        //                 docFileMap = new Map<String,String>();
        //                 docFileMap.put(selectedAdventureId, clonedAdventureId);
        //                 if(docFileMap.keySet().size() >0){
        //                     createContentVersionForChild(docFileMap);
        //                 }

                
        //                 List<Adventure_Step__c> adventureStepList = [SELECT Adventure__c,Name,Description__c,Icon_Image__c,Order__c,Subtitle__c,Title__c,Active__c,
        //                 (SELECT Id,Adventure_Step__c,Name,Description_URL__c,Description_Label__c,Order__c,Title__c,Tooltip_Description__c,Active__c,Completed_Manual__c FROM Step_Modules__r) 
        //                 FROM Adventure_Step__c WHERE Adventure__c = : cloneAdventure.Id];
                        
        //                 List<Step_Module__c> stepModuleList = [SELECT Id,Adventure_Step__c,Name,Active__c,Completed_Manual__c,Description_Label__c,Description_URL__c,Order__c,Title__c,Tooltip_Description__c,
        //                 (SELECT Id,Name,Step_Module__c,Title__c,Resource_Type__c,Content_URL__c,Order__c,Completed__c,Flow__c,Question_Response__c,Question_Text__c,Template__c	 FROM Module_Tasks__r)   
        //                 FROM Step_Module__c WHERE Adventure_Step__c IN (SELECT Id FROM Adventure_Step__c WHERE Adventure__c = : cloneAdventure.Id)];
                        
        //                 If(stepModuleList.size() > 0){
        //                     for(Step_Module__c stepsModule:stepModuleList ){
        //                         moduleTasksMap.put(stepsModule.Id,stepsModule.Module_Tasks__r);
        //                     }
        //                 }
        //                 // Adventure->Steps creation
                        
        //                 If(adventureStepList.size() >0){
        //                     for(Adventure_Step__c advStep :adventureStepList){
        //                         Adventure_Step__c clonedStep = advStep.Clone(false,true);
        //                         clonedStep.Adventure__c = newAdventure.Id;
        //                         clonedStepsList.add(clonedStep);
        //                         cloneStepModuleMap.put(clonedStep,advStep.Step_Modules__r);
        //                         stepsParentChildMap.put(advStep,clonedStep);
        //                         // Check files count in step
        //                         /*fileCounts = [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId =:advStep.Id];
        //                         if(fileCounts > 0){
        //                             stepsParentChildMap.put(advStep,clonedStep);
        //                         } */
        //                     }
        //                 }
        //                 If (clonedStepsList.size() > 0 ){
        //                     insert clonedStepsList;

        //                     //Check & clone files if there is any in Adventure->Steps
        //                     docFileMap = new Map<String,String>();
        //                     If(stepsParentChildMap.size() > 0){
        //                         for(Adventure_Step__c adveStep:stepsParentChildMap.keySet()){
        //                             Adventure_Step__c  newStep =  stepsParentChildMap.get(adveStep);
        //                             docFileMap.put(adveStep.Id,newStep.Id);
        //                         }
        //                         if(docFileMap.keySet().size() >0){
        //                             createContentVersionForChild(docFileMap);
        //                         }
        //                     }
                            
                            
        //                 }
        //                 // Adventure->Steps->Module creation
        //                 If(cloneStepModuleMap.size() >0){
        //                     for(Adventure_Step__c advStep: cloneStepModuleMap.keySet()){
        //                         for(Step_Module__c stepsModule: cloneStepModuleMap.get(advStep)){
        //                             Step_Module__c clonedModel = stepsModule.Clone(false,true); 
        //                             clonedModel.Adventure_Step__c =  advStep.Id;
        //                             clonedStepModuleList.add(clonedModel);
        //                             // Adventure->Steps->Module->Tasks creation
        //                             cloneModuleTaskMap.put(clonedModel,moduleTasksMap.get(stepsModule.Id).deepClone(false,false,false)); 
        //                             masterFilesTasksMap.put(clonedModel,moduleTasksMap.get(stepsModule.Id));
        //                         }
        //                     }
        //                 }
        //                 If(clonedStepModuleList.size() > 0 ){
        //                     insert clonedStepModuleList;

        //                     // Linking tasks with their module
        //                     Map<Module_Task__c,Module_Task__c> taskFilesMap = new Map<Module_Task__c,Module_Task__c>();
        //                     If(cloneModuleTaskMap.size() > 0){
        //                         for(Step_Module__c StepModule: cloneModuleTaskMap.keySet()){
        //                             for(Module_Task__c moduleTask: cloneModuleTaskMap.get(StepModule)){
        //                                 moduleTask.Step_Module__c =  StepModule.Id;
        //                                 moduleTask.Owner__c = null;
        //                                 moduleTask.Restrict_to_User__c = false;
        //                                 moduleTask.Completed__c = false;
        //                                 clonedModuleTasksList.add(moduleTask);
        //                             }
        //                         }   
        //                     }
        //                 }
                        
        //                 If(clonedModuleTasksList.size() > 0 ){
        //                     insert clonedModuleTasksList;
        //                     //Check & clone files if there is any in Adventure->Steps-->Module-->Task
        //                     If(masterFilesTasksMap.size() > 0){
        //                         docFileMap = new Map<String,String>();
        //                         for(Step_Module__c StepModule: masterFilesTasksMap.keySet()){
        //                             if ((masterFilesTasksMap.get(StepModule)).Size() > 0 ){
        //                                 for(Integer i=0;i < (masterFilesTasksMap.get(StepModule)).Size() ;i++){
        //                                     docFileMap.put((masterFilesTasksMap.get(StepModule))[i].Id,(cloneModuleTaskMap.get(StepModule))[i].Id);
        //                                 }
        //                             }
        //                         }  
                                
        //                         if(docFileMap.keySet().size() > 0){
        //                             createContentVersionForChild(docFileMap);
        //                         }
        //                     } 
        //                 }
                        
        //             }
        //         }
        //     }        
        // }catch(Exception ex){
        //     throw new AuraHandledException(ex.getMessage());
        // }
        return clonedAdventureId;
    }
    
// Vikram Sisodia 11-03-2020 : Copy the files from existing records
    @AuraEnabled
    public static void createContentVersionForChild(Map<String,String> processContentVersion){

        try{
             
            List<ContentDocumentLink> contentDocLinkList = new List<ContentDocumentLink>();
            Map<String,List<ContentDocumentLink>> filesMap = new  Map<String,List<ContentDocumentLink>>();

            List<ContentVersion> clonedContentVersion = new List<ContentVersion>();
            Map<String,String> filesCloneMap = new  Map<String,String>();

            if(processContentVersion.size() > 0){
                List<ContentDocumentLink> newList = new List<ContentDocumentLink>([SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: processContentVersion.keySet()]);
                //System.debug('1. List: ' +newList) ;
                if(newList.size() > 0 ){
                    for(ContentDocumentLink reccordContent:newList){
                        if (processContentVersion.containsKey(reccordContent.LinkedEntityId)){
                            String clonedRecordId = processContentVersion.get(reccordContent.LinkedEntityId);
                            filesCloneMap.put(reccordContent.ContentDocumentId,clonedRecordId);
                        }
                    }
                    //System.debug('2 List: ' +filesCloneMap) ;
                }
                if(filesCloneMap.size() > 0){
                    List<ContentVersion> oldContentVersionList = new List<ContentVersion>([SELECT Id,ContentLocation,PathOnClient,Title,ContentBodyId,ContentDocumentId,ContentUrl,VersionData  FROM ContentVersion where ContentDocumentId IN: filesCloneMap.keySet()]);
                    If(oldContentVersionList.size() > 0 ){
                        for(ContentVersion contentRecord :oldContentVersionList){
                            ContentVersion conVer = new ContentVersion();
                            conVer.ContentLocation = contentRecord.ContentLocation; 
                            conVer.PathOnClient = contentRecord.PathOnClient; 
                            conVer.Title = contentRecord.Title; 
                            conVer.VersionData = contentRecord.VersionData;
                            conVer.ContentUrl = contentRecord.ContentUrl;
                            conVer.CloneRecordId__c = filesCloneMap.get(contentRecord.ContentDocumentId);   // Custom field 'CloneRecordId__c' created in contentVersion object
                            clonedContentVersion.add(conVer);
                        }
                    }
                
                }
            }    
            if(clonedContentVersion.size() > 0){
                insert clonedContentVersion;
                //get id of newly created contentVersion records
                List<String> ContentDocumentId = new List<String>();
                for(ContentVersion contRecord:clonedContentVersion ){
                    ContentDocumentId.add(contRecord.Id);
                }
                //get the contentDocumentId & related record Id 'CloneRecordId__c'
                List<ContentVersion> conDoc = new List<ContentVersion>([SELECT ContentDocumentId,CloneRecordId__c FROM ContentVersion WHERE Id IN:ContentDocumentId]);

                //Create ContentDocumentLink
                for(ContentVersion cloneRecord:conDoc){
                    ContentDocumentLink cloneFile = new ContentDocumentLink();
                    cloneFile.ContentDocumentId = cloneRecord.ContentDocumentId; 
                    cloneFile.LinkedEntityId = cloneRecord.CloneRecordId__c;  
                    cloneFile.ShareType = 'V'; 
                    cloneFile.Visibility = 'AllUsers';
                    contentDocLinkList.add(cloneFile);
                }
                if(contentDocLinkList.size() > 0){
                    insert contentDocLinkList;
                }
            } 
        }catch(Exception ex){
                System.debug('Error mesage: '+ex.getMessage()+', Line number: '+ex.getLineNumber());
                throw new AuraHandledException(ex.getMessage());
        }
       
    }
 // Vikram Sisodia 14-02-2020 : adventure default configuration
    @AuraEnabled
    public static x7s_Adventure_Setting__mdt getConfiguration(){
        try{
            List<x7s_Adventure_Setting__mdt> adentureSetupList = [SELECT Enable_Checkbox_Display__c,Enable_New_Task_Flag__c,Full_Clone_Error_Text__c,Full_Clone_Success_Text__c,Override_Action_Color__c,Override_Link_Color__c,Task_Completion_Checked_Text__c,Task_Completion_Unchecked_Text__c 
            FROM x7s_Adventure_Setting__mdt WHERE 	DeveloperName = 'Default'];
            return adentureSetupList[0];
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }      
        
    }
    
    // Dhana Prasad 31-03-2020 
     @AuraEnabled
    public static Id cloneAdventureWithAccount(Id selectedAdventureId, Id AccountId){
       ID clonedAdventureId =null;
        try{
            
            Map<Adventure_Step__c,Adventure_Step__c> stepsParentChildMap = new Map<Adventure_Step__c,Adventure_Step__c>();
            Map<Module_Task__c,Module_Task__c> tasksParentChildMap = new Map<Module_Task__c,Module_Task__c>();
            Map<String,String> docFileMap ;
            Map<Id,List<ContentDocumentLink>> TasksDocumentLinkMap = new Map<Id,List<ContentDocumentLink>>();
            Map<Id,List<Module_Task__c>> moduleTasksMap = new Map<Id,List<Module_Task__c>>();
            Map<Step_Module__c,List<Module_Task__c>> masterFilesTasksMap = new  Map<Step_Module__c,List<Module_Task__c>>();
            Map<Adventure_Step__c,List<Step_Module__c>> cloneStepModuleMap =new Map<Adventure_Step__c,List<Step_Module__c>>();
            Map<Step_Module__c,List<Module_Task__c>> cloneModuleTaskMap = new Map<Step_Module__c,List<Module_Task__c>>();      
            List<Adventure_Step__c> clonedStepsList = new List<Adventure_Step__c>();
            List<Step_Module__c> clonedStepModuleList = new List<Step_Module__c>();
            List<Module_Task__c> clonedModuleTasksList = new List<Module_Task__c>();
            List<ContentDocumentLink> clonedTasksContectDocLinkList = new List<ContentDocumentLink>();
            List<ContentDocument> clonedTaskContentdocList = new List<ContentDocument>();
            Integer fileCounts =0;
            

            // Adventure creation
            if (selectedAdventureId !=null){
                System.debug('Selected Record Id:'+ selectedAdventureId);
                Adventure__c cloneAdventure = [SELECT Id,Name,Title__c,Header_Image__c,Active__c,Banner_Image__c,Description__c,
                Source_Template__c,Subtitle__c,Title_Image__c,Completed__c,Account__c,Template__c,Adventure_Setting__c, Show_Checkboxes__c 
                FROM Adventure__c WHERE Id =:selectedAdventureId LIMIT 1];
				 System.debug('cloneAdventure:'+ cloneAdventure);
                
                If(cloneAdventure != null){
                
                    Adventure__c newAdventure = cloneAdventure.clone(false,true);
                    if(newAdventure !=null){
                        newAdventure.Source_Template__c = cloneAdventure.Id;
                       newAdventure.Account__c = AccountId;
                        newAdventure.Template__c = false;
                        newAdventure.Completed__c = false;
                        newAdventure.Name = cloneAdventure.Name + ' Copy';
                        insert newAdventure;
                        //Check & clone files if there is any in adventure
                       
                        clonedAdventureId = newAdventure.Id; 

                        docFileMap = new Map<String,String>();
                        docFileMap.put(selectedAdventureId, clonedAdventureId);
                        if(docFileMap.keySet().size() >0){
                            createContentVersionForChild(docFileMap);
                        }

                
                        List<Adventure_Step__c> adventureStepList = [SELECT Adventure__c,Name,Description__c,Icon_Image__c,Order__c,Subtitle__c,Title__c,Active__c,
                        (SELECT Id,Adventure_Step__c,Name,Description_URL__c,Description_Label__c,Order__c,Title__c,Tooltip_Description__c,Active__c,Completed_Manual__c FROM Step_Modules__r) 
                        FROM Adventure_Step__c WHERE Adventure__c = : cloneAdventure.Id];
                        
                        List<Step_Module__c> stepModuleList = [SELECT Id,Adventure_Step__c,Name,Active__c,Completed_Manual__c,Description_Label__c,Description_URL__c,Order__c,Title__c,Tooltip_Description__c,
                        (SELECT Id,Name,Step_Module__c,Title__c,Resource_Type__c,Content_URL__c,Order__c,Completed__c,Flow__c,Question_Response__c,Question_Text__c,Template__c	 FROM Module_Tasks__r)   
                        FROM Step_Module__c WHERE Adventure_Step__c IN (SELECT Id FROM Adventure_Step__c WHERE Adventure__c = : cloneAdventure.Id)];
                        
                        If(stepModuleList.size() > 0){
                            for(Step_Module__c stepsModule:stepModuleList ){
                                moduleTasksMap.put(stepsModule.Id,stepsModule.Module_Tasks__r);
                            }
                        }
                        // Adventure->Steps creation
                        
                        If(adventureStepList.size() >0){
                            for(Adventure_Step__c advStep :adventureStepList){
                                Adventure_Step__c clonedStep = advStep.Clone(false,true);
                                clonedStep.Adventure__c = newAdventure.Id;
                                clonedStepsList.add(clonedStep);
                                cloneStepModuleMap.put(clonedStep,advStep.Step_Modules__r);
                                stepsParentChildMap.put(advStep,clonedStep);
                                // Check files count in step
                                /*fileCounts = [SELECT count() FROM ContentDocumentLink WHERE LinkedEntityId =:advStep.Id];
                                if(fileCounts > 0){
                                    stepsParentChildMap.put(advStep,clonedStep);
                                } */
                            }
                        }
                        If (clonedStepsList.size() > 0 ){
                            insert clonedStepsList;

                            //Check & clone files if there is any in Adventure->Steps
                            docFileMap = new Map<String,String>();
                            If(stepsParentChildMap.size() > 0){
                                for(Adventure_Step__c adveStep:stepsParentChildMap.keySet()){
                                    Adventure_Step__c  newStep =  stepsParentChildMap.get(adveStep);
                                    docFileMap.put(adveStep.Id,newStep.Id);
                                }
                                if(docFileMap.keySet().size() >0){
                                    createContentVersionForChild(docFileMap);
                                }
                            }
                            
                            
                        }
                        // Adventure->Steps->Module creation
                        If(cloneStepModuleMap.size() >0){
                            for(Adventure_Step__c advStep: cloneStepModuleMap.keySet()){
                                for(Step_Module__c stepsModule: cloneStepModuleMap.get(advStep)){
                                    Step_Module__c clonedModel = stepsModule.Clone(false,true); 
                                    clonedModel.Adventure_Step__c =  advStep.Id;
                                    clonedStepModuleList.add(clonedModel);
                                    // Adventure->Steps->Module->Tasks creation
                                    cloneModuleTaskMap.put(clonedModel,moduleTasksMap.get(stepsModule.Id).deepClone(false,false,false)); 
                                    masterFilesTasksMap.put(clonedModel,moduleTasksMap.get(stepsModule.Id));
                                }
                            }
                        }
                        If(clonedStepModuleList.size() > 0 ){
                            insert clonedStepModuleList;

                            // Linking tasks with their module
                            Map<Module_Task__c,Module_Task__c> taskFilesMap = new Map<Module_Task__c,Module_Task__c>();
                            If(cloneModuleTaskMap.size() > 0){
                                for(Step_Module__c StepModule: cloneModuleTaskMap.keySet()){
                                    for(Module_Task__c moduleTask: cloneModuleTaskMap.get(StepModule)){
                                        moduleTask.Step_Module__c =  StepModule.Id;
                                        moduleTask.Owner__c = null;
                                        moduleTask.Restrict_to_User__c = false;
                                        moduleTask.Completed__c = false;
                                        clonedModuleTasksList.add(moduleTask);
                                    }
                                }   
                            }
                        }
                        
                        If(clonedModuleTasksList.size() > 0 ){
                            insert clonedModuleTasksList;
                            //Check & clone files if there is any in Adventure->Steps-->Module-->Task
                            If(masterFilesTasksMap.size() > 0){
                                docFileMap = new Map<String,String>();
                                for(Step_Module__c StepModule: masterFilesTasksMap.keySet()){
                                    if ((masterFilesTasksMap.get(StepModule)).Size() > 0 ){
                                        for(Integer i=0;i < (masterFilesTasksMap.get(StepModule)).Size() ;i++){
                                            docFileMap.put((masterFilesTasksMap.get(StepModule))[i].Id,(cloneModuleTaskMap.get(StepModule))[i].Id);
                                        }
                                    }
                                }  
                                
                                if(docFileMap.keySet().size() > 0){
                                    createContentVersionForChild(docFileMap);
                                }
                            } 
                        }
                        
                    }
                }
            }        
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return clonedAdventureId;
    }

}