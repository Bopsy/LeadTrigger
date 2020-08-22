public without sharing class AccountMQLController {
    public Integer maxSearchResults = 1000;
    public List<String> queryFields = new List<String> {
        'Name',
        'MQL_Status__c',
        'Date_Submitted__c',
        'Date_Contacted__c',
        'Owner.Id',
        'Owner.Name'
    };
 
    public Account acc;

    // Constructor    
    public AccountMQLController(ApexPages.StandardController controller) {         
        acc = (Account)controller.getRecord();
    }

    public List<FSR__c> mqlRelatedList {
        get {
            return Database.query(
                'SELECT ' + String.join(queryFields, ',')
                + ' FROM FSR__c'
                + ' WHERE Contact__r.AccountId = \'' + acc.Id + '\''
                + ' ORDER BY ' + sortField + ' ' + sortDir
                + ' LIMIT ' + String.valueOf(maxSearchResults+1)
            );
        }
    }

    public string sortField {
        get { return (sortField == null) ? 'Name' : sortField; }
        set;
    }
    
    public string sortDir {
        get { return (sortDir == null) ? 'asc' : sortDir; }
        set;
    }

    // toggles the sorting of query from asc<-->desc
    public void toggleSort() {
        sortDir = sortDir.equals('asc') ? 'desc' : 'asc';
    }
}