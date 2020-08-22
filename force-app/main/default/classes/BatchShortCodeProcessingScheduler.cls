global class BatchShortCodeProcessingScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchShortCodeProcessing());
    }
}