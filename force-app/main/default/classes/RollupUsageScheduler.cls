global class RollupUsageScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new RollupAccountUsageTotal());
        Database.executeBatch(new RollupLeadUsageTotal());
    }
}