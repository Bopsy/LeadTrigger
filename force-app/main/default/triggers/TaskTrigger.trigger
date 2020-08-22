/*****
Trigger: TaskTrigger
@author: Jaya
*****/  
trigger TaskTrigger on Task(after insert) { 
    
    TaskTriggerHelper.getTasks(trigger.new);

}