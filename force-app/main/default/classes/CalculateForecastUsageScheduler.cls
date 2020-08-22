global class CalculateForecastUsageScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new CalculateForecastUsage(), 100);
    }
}