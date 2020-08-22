/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class OpportunityKnowledgeArticleSelectorTest {
    static Opportunity opp;
    static Account acc;
    static List<Account> accList;
    static List<KnowledgeArticleVersion> articleList;

    static testMethod void noOpptyGivenException() {
        setupTestRecords();
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController();
        System.debug('TEST METHOD: noOpptyGivenException');
    }

    static testMethod void badSoqlException() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', opp.Id);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController();
        obj.sortField = 'Invalid_Field';
        obj.toggleSort();
        obj.runSearch();
        System.debug('TEST METHOD: badSoqlException');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void linkArticle() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', opp.Id);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController();
        Integer max = 5;
        Integer i = 0;
        for (KnowledgeArticleVersion a : articleList) {
            obj.articleTitle = a.Title;
            obj.articleId = a.KnowledgeArticleId;
            obj.articleVersionId = a.Id;
            obj.linkArticle();
            if (i++ > 5)
                break;
        }
        obj.runSearch();
        System.debug('TEST METHOD: linkArticle');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void unlinkArticle() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', opp.Id);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController();
        KnowledgeArticleVersion a = articleList[0];
        obj.articleTitle = a.Title;
        obj.articleId = a.KnowledgeArticleId;
        obj.articleVersionId = a.Id;
        obj.linkArticle();
        obj.runSearch();
        for (OpportunityKnowledgeArticleController.ArticleRecord r : obj.searchResults) {
            if (r.isLinked) {
                obj.linkedArticleId = r.link.Id;
                obj.unlinkArticle();
                break;
            }
        }
        System.debug('TEST METHOD: unlinkArticle');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void searchPage() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', opp.Id);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController();
        obj.runSearch();
        System.debug('TEST METHOD: searchPage');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void searchPageMaxLimitExceeded() {
        setupTestRecords();
        Apexpages.currentPage().getParameters().put('id', opp.Id);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController();
        obj.maxSearchResults = 5;
        Apexpages.currentPage().getParameters().put('searchText', articleList[0].Title.substringBefore('-'));
        obj.runSearch();
        System.debug('TEST METHOD: searchPageMaxLimitExceeded');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void searchNoMatch() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(opp);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController(con);
        Apexpages.currentPage().getParameters().put('searchText', 'none');
        obj.runSearch();
        System.debug('TEST METHOD: searchNoMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void searchOneMatch() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(opp);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController(con);
        Apexpages.currentPage().getParameters().put('searchText', articleList[articleList.size()-1].Title);
        obj.runSearch();
        System.debug('TEST METHOD: searchOneMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }
    
    static testMethod void searchMultiMatch() {
        setupTestRecords(); 
        Apexpages.StandardController con = new ApexPages.StandardController(opp);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController(con);
        Apexpages.currentPage().getParameters().put('searchText', articleList[0].Title);
        obj.runSearch();
        System.debug('TEST METHOD: searchMultiMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }   
    
    static testMethod void searchMaxMatch() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(opp);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController(con);
        Apexpages.currentPage().getParameters().put('searchText', articleList[0].Title.substringBefore('-'));
        obj.runSearch();
        System.debug('TEST METHOD: searchMaxMatch');
        System.debug(obj.debugSoql);
        System.debug(obj.debugParameters);
    }

    static testMethod void toggleSort() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(opp);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController(con);
        obj.sortField = 'Account_SID__c';
        obj.toggleSort();
        obj.runSearch();
    }

  static testMethod void paginationControls() {
    setupTestRecords();
    Apexpages.currentPage().getParameters().put('id', opp.Id);
    OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController();
    obj.runSearch();
    Boolean hasNext = obj.hasNext;
    Boolean hasPrevious = obj.hasPrevious;
    obj.first();
    obj.next();
    obj.last();
    obj.previous();
    System.debug('TEST METHOD: paginationControls');
    System.debug(obj.debugSoql);
    System.debug(obj.debugParameters);
  }    

    static testMethod void nullSearchText() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(opp);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController(con);
        obj.searchText = null;
        String s = obj.searchText;
        obj.runSearch();
    }
    
    static testMethod void testDebug() {
        setupTestRecords();
        Apexpages.StandardController con = new ApexPages.StandardController(opp);
        OpportunityKnowledgeArticleController obj = new OpportunityKnowledgeArticleController(con);
        String soql = obj.debugSoql;
        String params = obj.debugParameters;
    }

    static void setupTestRecords() {
        acc = new Account(Name = 'Test Acc', Employee_Size__c = '0 - 50', Account_SID__c = 'abcdef1234567890');
        insert acc;

        opp = new Opportunity(Name = 'Test Opp', StageName = 'Pipeline', CloseDate = Date.today());
        insert opp;

        // Create the knowledge articles
        List<Knowledge__kav> aList = new List<Knowledge__kav>();
        Integer pageSize = (new OpportunityKnowledgeArticleController()).defaultPageSize;
        for (Integer i = 0; i < pageSize; i++)
            aList.add(new Knowledge__kav(Title='test-xyz'+i, Summary='test-xyz'+i, UrlName='xyz'+i));
        insert aList;
        Map<Id,Knowledge__kav> aMap = new Map<Id,Knowledge__kav>(aList);

        // Publish the articles
        // Requery to get the KnowledgeArticleId
        for (Knowledge__kav a : [Select KnowledgeArticleId from Knowledge__kav where ID IN :aMap.KeySet()])
            KbManagement.PublishingService.publishArticle(a.KnowledgeArticleId, true);

        articleList = [Select Id, Title, Summary, UrlName, KnowledgeArticleId from KnowledgeArticleVersion];
    }
}