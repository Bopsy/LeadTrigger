/** * * * * * * * * * * * *
*  Class Name:   AccountTriggerTest
*  Purpose:      Test class to Account Trigger
*  Author:       Vivek Somani
*  Company:      GoNimbly
*  Created Date: 07-Feb-2017
*  Type:         Test Class
** * * * * * * * * * * * */
@isTest
private class AccountTriggerTest {

  private static List<Account> accountList = new List<Account>();
  private static List<Task> taskList = new List<Task>();

  /* * * * * * * * * * * * *
  *  Method Name:  setup
  *  Purpose:      This method is used to create the test data.
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  static  void setup(Integer counter, Integer createdMonthChange, User taskCreatedByUser)
  {
    //create sample data for Account
    accountList = TestDataFactory.createAccountList(counter);
    insert accountList;

    //create sample data for Task
    taskList = new List<Task>();
    for(Account account : accountList)
    {
      taskList.addAll(TestDataFactory.createTasks(counter, account.Id, false));
    }

    if(taskCreatedByUser != null)
    {
      // creating task in some other user context
      System.runAs(taskCreatedByUser)
      {
        insert taskList;
      }
    }
    else
    {
      insert taskList;
    }

    // set created date for task records as per the createdMonthChange variable
    Integer monthChangeCounter = 1;
    for(Task task: taskList)
    {
      Test.setCreatedDate(task.Id, System.now().addMonths(createdMonthChange * monthChangeCounter));
      monthChangeCounter++;
    }

  }

  /* * * * * * * * * * * * *
  *  Method Name:  accountTrigger_scenario1
  *  Purpose:      This method is used to test trigger satisfying all conditions and Task present
  *                with CreatedDate before First_NPC_500_Date__c related to accounts
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  @isTest static void accountTrigger_scenario1() {
    Integer counter = 20;
    Integer months = -2;

    // create test data for batch
    setup(counter, months, NULL);

    Test.startTest();

      for(Account accountRecord: accountList)
      {
        accountRecord.First_NPC_500_Date__c = Date.Today();
      }
      update accountList;

    Test.stopTest();

    //assert checking if Pre_NPC_500_Connect_Date__c is updated for all Account records
    List<Account>  accountUpdatedList = [SELECT Id, Pre_NPC_500_Connect_Date__c FROM Account WHERE Pre_NPC_500_Connect_Date__c != NULL];
    System.assertEquals(accountUpdatedList.size(),counter);

    //assert checking if correct Date is populated in Account Pre_NPC_500_Connect_Date__c field
    for(Integer i = 0 ;i < accountUpdatedList.size() ; i++)
    {
      System.assert(accountUpdatedList[i].Pre_NPC_500_Connect_Date__c < System.now().Date(),'Accounts Pre NPC Connect Date should be populated with Task Created Date');
    }

  }

  /* * * * * * * * * * * * *
  *  Method Name:  accountTrigger_scenario2
  *  Purpose:      This method is used to test trigger satisfying all conditions and No Task present
  *                with CreatedDate before First_NPC_500_Date__c related to accounts
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  @isTest static void accountTrigger_scenario2() {
    Integer counter = 20;
    Integer months = 2;

    // create test data for batch
    setup(counter, months, NULL);

    Test.startTest();

      for(Account accountRecord: accountList)
      {
        accountRecord.First_NPC_500_Date__c = Date.Today();
      }
      update accountList;

    Test.stopTest();

    //assert checking if Pre_NPC_500_Connect_Date__c is updated for all Account records
    List<Account>  accountUpdatedList = [SELECT Id FROM Account WHERE Pre_NPC_500_Connect_Date__c != NULL];
    System.assertEquals(accountUpdatedList.size(),0);

  }

  /* * * * * * * * * * * * *
  *  Method Name:  accountTrigger_scenario3
  *  Purpose:      This method is used to test trigger satisfying all conditions and No Task present
  *                with CreatedDate before First_NPC_500_Date__c related to accounts and created by User
  *                with user name "API Eloqua"
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  @isTest static void accountTrigger_scenario3() {
    Integer counter = 20;
    Integer months = 2;

    User eloquaApiUser = TestDataFactory.createUser('System Administrator','API Eloqua', 5, true);

    // create test data for batch
    setup(counter, months, eloquaApiUser);

    Test.startTest();

      for(Account accountRecord: accountList)
      {
        accountRecord.First_NPC_500_Date__c = Date.Today();
      }
      update accountList;

    Test.stopTest();

    //assert checking if Pre_NPC_500_Connect_Date__c is not updated for all Account records
    List<Account>  accountUpdatedList = [SELECT Id FROM Account WHERE Pre_NPC_500_Connect_Date__c != NULL];
    System.assertEquals(accountUpdatedList.size(),0);

  }

  static testMethod void accountTrigger_TasksOnlyOnContact()
  {
    final Integer NUM_RECORDS = 10;

    accountList = TestDataFactory.createAccountList(NUM_RECORDS);
    insert accountList;

    List<Contact> testContacts = new List<Contact>();
    for(Account anAccount : accountList)
    {
      Contact newContact = TestDataFactory.createContactList(1)[0];
      newContact.AccountId = anAccount.Id;
      testContacts.add(newContact);
    }
    insert testContacts;

    taskList = new List<Task>();
    for(Contact aContact : testContacts)
    {
      Task newTask = TestDataFactory.createTasks(1, NULL, FALSE)[0];
      newTask.WhoId = aContact.Id;
      newTask.Type = 'Meeting';
      taskList.add(newTask);
    }
    insert taskList;

    Test.startTest();

      for(Account anAccount : accountList)
      {
        anAccount.First_NPC_500_Date__c = Date.today().addDays(1);
      }
      update accountList;

    Test.stopTest();

    List<Account> updatedAccounts = [ SELECT Id, Pre_NPC_500_Connect_Date__c FROM Account ];
    System.assertEquals(NUM_RECORDS, updatedAccounts.size(), 'There should be as many Accounts as created');
    for(Account anAccount : updatedAccounts)
    {
      System.assertEquals(Date.today(), anAccount.Pre_NPC_500_Connect_Date__c, 'The Pre date should be populated');
    }
  }
}