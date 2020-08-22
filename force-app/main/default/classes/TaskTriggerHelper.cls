/**********
Class:TaskTriggerHelper
***********/
public with sharing class TaskTriggerHelper {

   public Static Final String LEAD_RESPONDED = 'Responded';
   public Static Final String LEAD_BRD_ENGAGED = 'BDR Engaged';
   public Static Final String LEAD_OPEN = 'Open';
   public Static Final String LEAD_CONTACTED = 'Contacted';
   public static void getTasks(List<Task> taskList)
   {
        Map<String,TaskHelperConstant__c> taskConstant = new Map<String,TaskHelperConstant__c>();
        taskConstant = TaskHelperConstant__c.getAll();
        System.debug('taskConstant:'+taskConstant);
        Map<Id,String> leadIdStatusMap = new Map<Id,String>();
        for(Task taskObj : taskList)
        {
            String leadId = String.valueOf(taskObj.WhoId) != null && String.valueOf(taskObj.WhoId).startsWith('00Q')?taskObj.WhoId:null;
            String[] emailContent = new List<String>();
            if(leadId != null && leadId !='')
            {
                if(taskObj.Description != null)
                {
                   emailContent = taskObj.Description.split('\n');
                }
                if(!emailContent.isEmpty())
                {
                    //leadStatu= Responded
                    Boolean senderFlag = false;
                    Boolean respondsignatureFlag = false;
                    Boolean rbrdsignatureFlag = false;
                    String sender;
                    for(String str :emailContent)
                    {
                        if(str.startsWith('Additional To:'))
                        {
                            sender = str.substring(str.indexOf(':')+1, str.length());
                            sender = '<'+sender;
                            sender = sender.remove(' ');
                        }
                        String previousMail = str.remove(' ');
                        if(sender != null && previousMail.contains(sender)) 
                        {
                            senderFlag = true;
                            break;
                        }
                        
                    }
                    if(taskObj.Description.contains(taskConstant.get(LEAD_BRD_ENGAGED).Signature__c))
                    {
                        rbrdsignatureFlag = true;
                    }
                    System.debug('rsp:'+taskObj.Description.contains(taskConstant.get(LEAD_RESPONDED).Signature__c));
                    if(taskObj.Description.contains(taskConstant.get(LEAD_RESPONDED).Signature__c))
                    {
                        respondsignatureFlag = true;
                    }
                    //if(senderFlag && respondsignatureFlag && leadId != null)
                    if(respondsignatureFlag && leadId != null)
                    {
                        leadIdStatusMap.put(leadId,LEAD_RESPONDED);
                    }
                    //if(senderFlag && rbrdsignatureFlag  && leadId != null)
                    if(rbrdsignatureFlag  && leadId != null)
                    {
                        leadIdStatusMap.put(leadId,LEAD_BRD_ENGAGED);
                    }
                    System.debug('senderFlag:'+senderFlag+' respondsignatureFlag:'+respondsignatureFlag+' rbrdsignatureFlag:'+rbrdsignatureFlag);
                }
            }
        }
        System.debug('leadIdStatusMap:'+leadIdStatusMap);
        if(!leadIdStatusMap.isEmpty())
        {
            leadUpdate(leadIdStatusMap);
        } 
   }
      
   public static void leadUpdate(Map<Id,String> leadIdStatusMap)
    {
        List<Lead> updateLeadList = new List<Lead>();
        List<String> statusnotIn = new List<String>{LEAD_RESPONDED,LEAD_BRD_ENGAGED};
        for(Lead leadRec : [SELECT Id,Status FROM Lead WHERE Id IN: leadIdStatusMap.keySet() 
                                           AND Status NOT IN: statusnotIn])
        {
        	if(leadRec.Status.equalsIgnoreCase(LEAD_OPEN) || leadRec.Status.equalsIgnoreCase(LEAD_CONTACTED))
            {
            	leadRec.Status = leadIdStatusMap.get(leadRec.Id);
                updateLeadList.add(leadRec);
            }
        }
        System.debug('updateLeadList:'+updateLeadList);
        if(!updateLeadList.isEmpty())
        {
            update updateLeadList;
        }
    }
 

}