global class BatchAccountSetLastSDRActivityScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchAccountSetLastSDRActivity());
    }
}