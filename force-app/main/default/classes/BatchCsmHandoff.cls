/* * * * * * * * * * * * * *
*  Class Name:   BatchCsmHandoff
*  Purpose:      Batch class to track on an Account level the Tasks immediately before
*                and after a specific milestone triggers.
*  Author:       Vivek Somani
*  Company:      GoNimbly
*  Created Date: 07-Feb-2017
*  Type:         Batch Class
* * * * * * * * * * * * */
global class BatchCsmHandoff implements Database.Batchable<sObject>, Database.Stateful, Schedulable
{
  String errors = '';
  static final Set<String> TASK_TYPES = new Set<String>{ 'Call', 'Email', 'Meeting', 'LinkedIn InMail', 'Discovery Call', 'Follow Up Call', 'Intro Call', 'QBR'};
  static final Set<String> eloquaApiUserNameSet = new Set<String>{ 'API Eloqua', 'Eloqua Marketing' };

  // start method of the batch class
  global Database.QueryLocator start(Database.BatchableContext BC)
  {
    return Database.getQueryLocator([SELECT Id, First_NPC_500_Date__c FROM Account WHERE First_NPC_500_Date__c != NULL AND Post_NPC_500_Connect_Date__c = NULL]);
  }

  //execute method of the batch class
  global void execute(Database.BatchableContext BC, List<Account> scope)
  {
    // fetch users with full names specified in set declared as class variable
    List<User> restrictedUsers = [Select Id from User where Name IN :eloquaApiUserNameSet];

    Map<Id, Contact> relatedContacts = new Map<Id, Contact>([ SELECT Id, AccountId FROM Contact WHERE AccountId IN :scope ]);

    // Fetch all filtered task records related to accounts
    List<Task> taskList = [Select CreatedDate, WhatId, WhoId, Type, OwnerId from Task
                           where (WhatId IN :scope OR WhoId IN :relatedContacts.keySet())
                           and (Type IN :TASK_TYPES OR (Type = 'Email' AND Subject LIKE '%RE:%'))
                           and Status = 'Completed'
                           and CreatedById NOT IN :restrictedUsers
                           ORDER BY CreatedDate ASC];

    if(taskList != null && taskList.size() > 0)
    {
      Set<Id> taskOwnerIds = new Set<Id>();
      for(Task aTask : taskList)
      {
        taskOwnerIds.add(aTask.OwnerId);
      }
      Map<Id, User> taskOwners = new Map<Id, User>([ SELECT Id, Role_Team__c FROM User WHERE Id IN :taskOwnerIds ]);

      Map<Id,List<Task>> tasksByAccountIdMap = new Map<Id,List<Task>>();
      for(Task taskRecord : taskList)
      {
        Id accountId = taskRecord.WhatId;
        if(accountId == NULL && relatedContacts.containsKey(taskRecord.WhoId))
        {
          accountId = relatedContacts.get(taskRecord.WhoId).AccountId;
        }

        // populate map of list of Task by account id
        if(tasksByAccountIdMap.get(accountId) == null)
        {
          tasksByAccountIdMap.put(accountId,new List<Task>());
        }
        tasksByAccountIdMap.get(accountId).add(taskRecord);
      }

      List<Account> accountListToUpdate = new List<Account>();
      for(Account account :scope)
      {
        List<Task> accountTaskList = tasksByAccountIdMap.get(account.Id);
        if(accountTaskList != null && accountTaskList.size() > 0)
        {
          for(Task task: accountTaskList)
          {
            // checking for earliest Task by CreatedDate after First_NPC_500_Date__c
            if(account.First_NPC_500_Date__c <= task.CreatedDate.Date())
            {
              account.Post_NPC_500_Connect_Date__c = task.CreatedDate.Date();
              account.post_npc_500_connect_type__c = task.Type;
              if(taskOwners.containsKey(task.OwnerId))
              {
                account.post_npc_500_connect_team__c = taskOwners.get(task.OwnerId).Role_Team__c;
              }
              accountListToUpdate.add(account);
              break;
            }
          }
        }
      }

      // update the Account stamped with the task's created date
      if(accountListToUpdate.size() > 0)
      {
        List<Database.SaveResult> saveResults = Database.update(accountListToUpdate, false);
        errors += BatchUtils.processSaveResult(accountListToUpdate, saveResults);
      }
    }
  }

  //finish method of the batch class
  public void finish(Database.BatchableContext BC)
  {
    BatchUtils.finish('BatchCsmHandoff',BC.getJobId(),errors);
  }

  //execute method for scheduling batch class
  public void execute(SchedulableContext sc)
  {
    BatchCsmHandoff theBatch = new BatchCsmHandoff();
    database.executebatch(theBatch);
  }
}