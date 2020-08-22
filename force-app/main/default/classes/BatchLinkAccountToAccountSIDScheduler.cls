global class BatchLinkAccountToAccountSIDScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchLinkAccountToAccountSID());
    }
}