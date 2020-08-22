trigger MergeForecasts on Account (after delete) {

    // Identify accounts that are being delete as a
    // results of an account merge
    //Set<Id> mergedAccountIds = new Set<Id>();
    //for (Account a : Trigger.old) {
    //    if (a.MasterRecordId != a.Id) {
    //        System.debug('======> ACCOUNT MERGED (' + a.Id + ', ' + a.Name + ')');
    //        mergedAccountIds.add(a.MasterRecordId);
    //        mergedAccountIds.add(a.Id);
    //    }
    //}
    
    //if (!mergedAccountIds.isEmpty()) {
    //    TwilioForecastHandler.mergeForecasts(new List<Id>(mergedAccountIds));
    //}
}