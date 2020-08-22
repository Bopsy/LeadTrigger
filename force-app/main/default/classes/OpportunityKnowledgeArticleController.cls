public class OpportunityKnowledgeArticleController {

    public Integer maxSearchResults = 1000;
  public Integer defaultPageSize = 10;

    public Opportunity o {get;set;}

  // properties holding the selected article
    public String articleId {get;set;}
    public String articleVersionId {get;set;}
    public String articleTitle {get;set;}
    public String articleSummary {get;set;}
    public String linkedArticleId {get;set;}

    public OpportunityKnowledgeArticleController() {
        String oppId = Apexpages.currentPage().getParameters().get('id');
        List<Opportunity> opp = [ SELECT Id FROM Opportunity WHERE Id = :oppId ];
        if (opp.size() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - Opportunity not found having that record ID.'));
        } else {
            this.o = opp[0];
        }
        runSearch();
    }

    public OpportunityKnowledgeArticleController(ApexPages.StandardController controller) {
        this.o = (Opportunity)controller.getRecord();
        runSearch();
    }

    // the results from the search. do not init the results or a blank rows show up initially on page load
    public List<ArticleRecord> searchResults {get;set;}
    public List<ArticleRecord> searchResultsPage {get;set;}
    public String totalRecordsFound {get;set;}

  // pagination properties and methods
  public Integer pageSize    { get { return (pageSize == null) ? defaultPageSize : pageSize; } set;}
  public Integer pageNumber  { get { return (pageNumber == null || pageNumber < 1) ? 1 : pageNumber; } set;}

  public Integer noOfRecords { get { return (searchResults == null) ? 0 : searchResults.size(); } }
  public Boolean hasNext     { get { return (noOfRecords == 0 || noOfRecords <= (pageSize * pageNumber)) ? false : true; } }
  public Boolean hasPrevious { get { return (noOfRecords == 0 || pageNumber <= 1) ? false : true; } }

  public PageReference first()    { pageNumber = 1; refresh(); return null; }
  public PageReference last()     { pageNumber = Integer.valueOf(Math.ceil(Decimal.valueOf(noOfRecords) / Decimal.valueOf(pageSize)));  refresh(); return null; }
  public PageReference previous() { pageNumber--; refresh(); return null; }
  public PageReference next()     { pageNumber++;  refresh(); return null; }
  public void refresh()           { searchResultsPage = getPage(searchResults, pageNumber, pageSize); }

  private List<ArticleRecord> getPage(List<ArticleRecord> objs, Integer pageNumber, Integer pageSize) {
    Integer pageFirstItem = pageNumber <= 1 ? 0 : ((pageNumber - 1) * pageSize);
    Integer pageLastItem = (pageFirstItem + pageSize) > objs.size() ? objs.size() : (pageFirstItem + pageSize);
    System.debug(LoggingLevel.Info, 'objs = ' + objs);
    System.debug(LoggingLevel.Info, 'pageFirstItem(' + pageFirstItem + ')');
    System.debug(LoggingLevel.Info, 'pageLastItem(' + pageLastItem + ')');
    List<ArticleRecord> newList = new List<ArticleRecord>();
    for (Integer i = pageFirstItem; i < pageLastItem; i++) {
      newList.add(objs.get(i));
      System.debug(LoggingLevel.Info, 'Adding(' + i + ')');
    }
    System.debug(LoggingLevel.Info, 'Page Size(' + newList.size() + ')');
    return newList;
  }

    // the soql without the order and limit
    private String soql {get;set;}

    private String baseQuery() {
      return 'SELECT Id, Title, Summary, KnowledgeArticleId, ArticleNumber, UrlName FROM KnowledgeArticleVersion';
    }
    
    // If the summaryMatch is an empty string then no soql to execute
    // because there could be too many records to query
    private String baseQuery(String summaryMatch) {
      return String.isBlank(summaryMatch) ? '' : baseQuery()+' WHERE PublishStatus = \'Online\' AND Summary LIKE \'%' + summaryMatch + '%\'';
    }

    // If a list of linked articles are supplied return soql to query
    // their KnowledgeArticleVersion records
    private String baseQuery(List<LinkedArticle> linkedArticles) {
    if (!linkedArticles.isEmpty()) {
        List<Id> ids = new List<Id>();
        for (LinkedArticle a : linkedArticles) {
          ids.add(a.KnowledgeArticleVersionId);
        }
        return baseQuery()+' WHERE Id IN (\'' + String.join(ids, '\',\'') + '\')';
      }
      return '';
    }

    // the text in the search box
    public string searchText {
        get { return (searchText == null) ? '' : searchText; }
        set;
    }
    
    public string sortField {
      get { return (sortField == null) ? 'Title' : sortField; }
      set;
    }
    
    public string sortDir {
      get { return (sortDir == null) ? 'asc' : sortDir; }
      set;
    }

    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        // simply toggle the direction
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
        // run the query again
    runQuery();
    }

    public void resetSearch() {
    articleId = null;
    articleVersionId = null;
    articleTitle = null;
    articleSummary = null;
    linkedArticleId = null;

    if (searchResults == null) {
      searchResults = new List<ArticleRecord>();
      searchResultsPage = new List<ArticleRecord>();
        } else {
      searchResults.clear();
      searchResultsPage.clear();
        }
    }

    // runs the actual query
    public void runQuery() {
        try {            
      resetSearch();
      
      // Get linked articles for the opportunity
      List<LinkedArticle> linkedArticles = (o == null) ? new List<LinkedArticle>() : [ SELECT Id, KnowledgeArticleVersionId FROM LinkedArticle WHERE Opportunity__c = :o.Id ];
      System.debug('INITIALIZE - linkedArticles Size = ' + linkedArticles.size());
      System.debug('INITIALIZE - linkedArticles = ' + linkedArticles);

      // In no soql then no search criteria was given, therefore, query just all linked arcticles instead,
      // otherwise, query articles matching the search criteria
      List<KnowledgeArticleVersion> results = new List<KnowledgeArticleVersion>();
      if (String.isBlank(soql)) {
        System.debug('Displaying only linked articles');
              if (!linkedArticles.isEmpty())
                results = Database.query(baseQuery(linkedArticles) + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults+1));
      } else {
        System.debug('Displaying matching articles');
        results = Database.query(soql + ' ORDER BY ' + sortField + ' ' + sortDir + ' LIMIT ' + String.valueOf(maxSearchResults+1));
      }

      // Correlate returned articles with linked articles
            for (KnowledgeArticleVersion a : results) {
          if (linkedArticles.isEmpty()) {
            System.debug('Article is not linked: ' + a);
            searchResults.add(new ArticleRecord(a));
            System.debug('Add to Search Results: ' + searchResults);
          } else {
            Boolean articleLinked = false;
            for (Integer i = linkedArticles.size() - 1; i >= 0; i--) {
              if (a.Id == linkedArticles[i].KnowledgeArticleVersionId) {
              System.debug('Article is linked: ' + a + ' -> ' + linkedArticles[i]);
                searchResults.add(new ArticleRecord(a, linkedArticles[i]));
                linkedArticles.remove(i);
                articleLinked = true;
                break;
              }
            }
            if (!articleLinked) {
              System.debug('Article is not linked: ' + a);
              searchResults.add(new ArticleRecord(a));
            }
          }
      }
      System.debug('Search Results: ' + searchResults);
            
            if (searchResults.size() == 0) {
                totalRecordsFound = 'No matches';
            } else if (searchResults.size() == 1) {
                totalRecordsFound = '1 match found';
            } else if (searchResults.size() > maxSearchResults) {
        searchResults.remove(maxSearchResults);
                totalRecordsFound = String.valueOf(searchResults.size()) + '+ matches found (showing only ' + String.valueOf(maxSearchResults) + ')';
            } else if (searchResults.size() > 1) {
                totalRecordsFound = String.valueOf(searchResults.size()) + ' matches found';
            }
            
      pageNumber = 1;
            refresh();
            System.debug(LoggingLevel.INFO, 'pageNumber(' + pageNumber + ')');
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Ooops! - ' + e.getMessage()));
        }
    }

    // fired when the search button is clicked
    public PageReference runSearch() {
        String searchText = Apexpages.currentPage().getParameters().get('searchText');
        soql = baseQuery(searchText);
        runQuery();
        return null;
    }
    
    public PageReference unlinkArticle() {
    LinkedArticle article = new LinkedArticle(Id = linkedArticleId);
    System.debug(article);
      try {
        delete article;
        resetSearch();
          runQuery();
      } catch (System.DMLException e) {
        ApexPages.addMessages(e);
      }
      return null;
  }

    public PageReference linkArticle() {
    LinkedArticle article = new LinkedArticle(
      Name = articleTitle,
      KnowledgeArticleId = articleId,
      KnowledgeArticleVersionId = articleVersionId,
      Opportunity__c = o.Id
    );
    System.debug(article);
      try {
        insert article;
        resetSearch();
          runQuery();
      } catch (System.DMLException e) {
        ApexPages.addMessages(e);
      }
      return null;
  }

  public class ArticleRecord {
      public KnowledgeArticleVersion article {get;set;}
      public LinkedArticle link {get;set;}
      public Boolean isLinked {get { return link != null; } set;}

    public ArticleRecord(KnowledgeArticleVersion a) {
      this.article = a;
    }

    public ArticleRecord(KnowledgeArticleVersion a, LinkedArticle l) {
      this.article = a;
      this.link = l;
    }
  }

  // format the soql for display on the visualforce page
  public String debugSoql {get { return soql + ' limit 20'; } set;}
    
  // format the parameters for display on the visualforce page
  public String debugParameters {get { return String.join(Apexpages.currentPage().getParameters().values(), ','); } set;}

}