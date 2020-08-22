/** * * * * * * * * * * * *
*  Class Name:   BatchCsmHandoffTest
*  Purpose:      Test class to BatchCsmHandoff
*  Author:       Vivek Somani
*  Company:      GoNimbly
*  Created Date: 07-Feb-2017
*  Type:         Test Class
** * * * * * * * * * * * */
@isTest
private class BatchCsmHandoffTest {

  private static List<Account> accountList = new List<Account>();
  private static List<Task> taskList = new List<Task>();

  /* * * * * * * * * * * * *
  *  Method Name:  setup
  *  Purpose:      This method is used to create the test data.
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  static void setup(Integer counter, Integer createdMonthChange, User taskCreatedByUser)
  {
    //create sample data for Account
    accountList = TestDataFactory.createAccountList(counter);
    for(Account accountRecord: accountList)
    {
      accountRecord.First_NPC_500_Date__c = Date.Today();
      accountRecord.Pre_NPC_500_Connect_Date__c = Date.Today().addMonths(-2);
    }
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
  *  Method Name:  batchCsmHandoff_scenario1
  *  Purpose:      This method is used to call the BatchCsmHandoff batch class satisfying all conditions
  *                and Task present with CreatedDate after First_NPC_500_Date__c related to accounts
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  @isTest static void batchCsmHandoff_scenario1() {
    Integer counter = 20;
    Integer months = 2;

    // create test data for batch
    setup(counter, months, NULL);

    Test.startTest();

      BatchCsmHandoff batchCsmHandoff = new BatchCsmHandoff();
      database.executebatch(batchCsmHandoff);

    Test.stopTest();

    //assert checking if Post_NPC_500_Connect_Date__c is updated for all Account records
    List<Account>  accountUpdatedList = [SELECT Id, Post_NPC_500_Connect_Date__c FROM Account WHERE Post_NPC_500_Connect_Date__c != NULL];
    System.assertEquals(accountUpdatedList.size(),counter);

    //assert checking if correct Date is populated in Account Post_NPC_500_Connect_Date__c field
    for(Integer i = 0 ;i < accountUpdatedList.size() ; i++)
    {
      System.assert(accountUpdatedList[i].Post_NPC_500_Connect_Date__c > System.now().Date(),'Accounts post NPC Connect Date should be populated with Task Created Date');
    }

  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchCsmHandoff_scenario2
  *  Purpose:      This method is used to call the BatchCsmHandoff batch class satisfying all conditions
  *                and No Task present with CreatedDate after First_NPC_500_Date__c related to accounts
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  @isTest static void batchCsmHandoff_scenario2() {
    Integer counter = 20;
    Integer months = -2;

    // create test data for batch
    setup(counter, months, NULL);

    Test.startTest();

      BatchCsmHandoff batchCsmHandoff = new BatchCsmHandoff();
      database.executebatch(batchCsmHandoff);

    Test.stopTest();

    //assert checking if Post_NPC_500_Connect_Date__c is updated for all Account records
    List<Account>  accountUpdatedList = [SELECT Id FROM Account WHERE Post_NPC_500_Connect_Date__c != NULL];
    System.assertEquals(accountUpdatedList.size(),0);

  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchCsmHandoff_scenario3
  *  Purpose:      This method is used to call the BatchCsmHandoff batch class satisfying all conditions
  *                and Task created by User with user name "API Eloqua"
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  @isTest static void batchCsmHandoff_scenario3() {
    Integer counter = 20;
    Integer months = 2;

    User eloquaApiUser = TestDataFactory.createUser('System Administrator','API Eloqua', 5, true);

    // create test data for batch
    setup(counter, months, eloquaApiUser);

    Test.startTest();

      BatchCsmHandoff batchCsmHandoff = new BatchCsmHandoff();
      database.executebatch(batchCsmHandoff);

    Test.stopTest();

    //assert checking if Post_NPC_500_Connect_Date__c is not updated for all Account records
    List<Account>  accountUpdatedList = [SELECT Id FROM Account WHERE Post_NPC_500_Connect_Date__c != NULL];
    System.assertEquals(accountUpdatedList.size(),0);

  }

  /* * * * * * * * * * * * *
  *  Method Name:  batchCsmHandoff_schedule
  *  Purpose:      This method is used to start the execution of BatchCsmHandoff batch class through scheduling
  *  Author:       Vivek Somani
  *  Company:      GoNimbly
  *  Created Date: 07-Feb-2017
  * * * * * * * * * * * * */
  static testMethod void batchCsmHandoff_schedule()
  {
    Integer counter = 20;
    Integer months = 1;
    String jobId;
    String CRON_EXP = '0 0 * * * ?';

    // create test data for batch
    setup(counter, months, NULL);

    Test.startTest();
     jobId = System.schedule('BatchCsmHandoff - Hourly Test', CRON_EXP, new BatchCsmHandoff());
    Test.stopTest();

    // Get the information from the CronTrigger API object
    CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(CRON_EXP, cronTrigger.CronExpression);
  }

  static testMethod void batchCsmHandoff_TasksOnlyOnContact()
  {
    final Integer NUM_RECORDS = 10;

    accountList = TestDataFactory.createAccountList(NUM_RECORDS);
    for(Account anAccount : accountList)
    {
      anAccount.First_NPC_500_Date__c = Date.today().addDays(-1);
    }
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
      newTask.Type = 'Email';
      taskList.add(newTask);
    }
    insert taskList;

    Test.startTest();

      Database.executeBatch(new BatchCsmHandoff());

    Test.stopTest();

    List<Account> updatedAccounts = [ SELECT Id, Post_NPC_500_Connect_Date__c FROM Account ];
    System.assertEquals(NUM_RECORDS, updatedAccounts.size(), 'There should be as many Accounts as created');
    for(Account anAccount : updatedAccounts)
    {
      System.assertEquals(Date.today(), anAccount.Post_NPC_500_Connect_Date__c, 'The Post date should be populated');
    }
  }
}