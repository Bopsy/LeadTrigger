@isTest
private class Test_reassignContactOwnerToAccountOwner
{
    static testMethod void testContactInsert()
    {
           //Setup the Account record
           Account acc = new Account();
           acc.Name = 'Twilio';
           acc.ownerid = '005400000015KCCAA2';
           insert acc;
           
           Test.startTest();
           
           //Setup the Contact as being on account acc
           Contact con = new Contact();
           con.accountid = acc.id;
           con.LastName = 'Jordan';
           con.ownerid = '005400000015KC7AAM';
           insert con;
           
           //Update the record to see if the trigger fires
           //con.FirstName = 'Andrew';
           //update con;
           
                      
           //Test to see if the ownerids have been set to equal
           Contact conInserted = [SELECT ownerid FROM Contact WHERE Id = :con.Id];
           System.assertEquals(conInserted.ownerid, acc.ownerid);
    }
    
    static testMethod void testContactUpdate()
    {
           //Setup the Account record
           Account acc = new Account();
           acc.Name = 'Twilio';
           acc.ownerid = '005400000015KCCAA2';
           insert acc;
           
           Test.startTest();
           
           //Setup the Contact as being on account acc
           Contact con = new Contact();
           con.accountid = acc.id;
           con.LastName = 'Jordan';
           con.ownerid = '005400000015KCCAA2';
           insert con;
           
           con.ownerid = '005400000015ABCAA2';
           update con;
              
           //Test to see if the ownerids have been set to equal
           Contact conInserted = [SELECT ownerid FROM Contact WHERE Id = :con.Id];
           System.assertEquals(conInserted.ownerid, acc.ownerid);
    }
}