@isTest
public class CIFUtilityTest {

    public static testMethod void testGetOperatorsSimple(){
        String Logic = '1 AND 2 OR 3';
        CIFUtility cifu = new CIFUtility();
        
        List<String> operators;
        List<String> operands;
        
        Test.startTest();
        	operators = cifu.getOperators(Logic);
        Test.stopTest();
        
        System.assertEquals(new List<String>{'1','2','3'},operators);
    }
    
}