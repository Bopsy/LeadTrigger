public class ForecastSchedulesController
{
  public ForecastSchedulesController( ApexPages.StandardController standardCont ) {}

  public class MissingInformationException extends System.Exception {}

  @RemoteAction
  public static Opportunity getOpportunity( Id opportunityId )
  {
    Opportunity theOpportunity = queryOpportunity( opportunityId );
    if( theOpportunity.Forecast_Schedules__r.isEmpty() )
    {
      if( theOpportunity.Launch_Date__c == NULL || theOpportunity.Contract_Terms_Months__c == NULL )
      {
        throw new MissingInformationException( 'Launch Date and Contract Terms must be set on the Opportunity.' );
      }

      Date forecastDate = theOpportunity.Launch_Date__c;
      Double forecastAmount = theOpportunity.Amount / theOpportunity.Contract_Terms_Months__c;
      List<Forecast_Schedule__c> newForecasts = new List<Forecast_Schedule__c>();
      for( Integer index = 0; index < theOpportunity.Contract_Terms_Months__c; index++ )
      {
        Forecast_Schedule__c aForecast = new Forecast_Schedule__c();
        aForecast.Opportunity__c = theOpportunity.Id;
        aForecast.Forecast_Amount__c = forecastAmount;
        newForecasts.add( aForecast );

        aForecast.Start_Date__c = forecastDate;
        forecastDate = aForecast.Start_Date__c.addMonths( 1 ).toStartOfMonth();
        aForecast.End_Date__c = forecastDate.addDays( -1 );
      }

      insert newForecasts;
      theOpportunity = queryOpportunity( opportunityId );
    }

    return theOpportunity;
  }

  private static Opportunity queryOpportunity( Id opportunityId )
  {
    return [ SELECT Id, Name, StageName, Amount, Launch_Date__c, Contract_Terms_Months__c,
                ( SELECT Id, Forecast_Amount__c, Start_Date__c, End_Date__c, Forecasted_Amount_at_Close__c, Is_Pilot__c
                  FROM Forecast_Schedules__r ORDER BY Start_Date__c ASC NULLS LAST )
              FROM Opportunity WHERE Id = :opportunityId ];
  }

  @RemoteAction
  public static List<Forecast_Schedule__c> updateForecasts( List<Forecast_Schedule__c> schedulesToUpdate )
  {
    for( Forecast_Schedule__c aForecast : schedulesToUpdate )
    {
      if( aForecast.End_Date__c == NULL && aForecast.Start_Date__c != NULL )
      {
        Date endOfMonth = aForecast.Start_Date__c.addMonths( 1 ).toStartOfMonth().addDays( -1 );
        aForecast.End_Date__c = endOfMonth;
      }
    }
    upsert schedulesToUpdate;

    return schedulesToUpdate;
  }

  @RemoteAction
  public static Forecast_Schedule__c newSchedule( Id opportunityId )
  {
    AggregateResult maxDateResult = [ SELECT MAX(Start_Date__c) maxDate FROM Forecast_Schedule__c WHERE Opportunity__c = :opportunityId ];
    Date maxDate = (Date)maxDateResult.get( 'maxDate' );

    Forecast_Schedule__c newForecast = new Forecast_Schedule__c();
    newForecast.Opportunity__c = opportunityId;
    newForecast.Forecast_Amount__c = 0.0;
    newForecast.Start_Date__c = maxDate.addMonths( 1 ).toStartOfMonth();
    newForecast.End_Date__c = maxDate.addMonths( 2 ).toStartOfMonth().addDays( -1 );
    insert newForecast;

    return newForecast;
  }

  @RemoteAction
  public static Forecast_Schedule__c deleteSchedule( Id scheduleId )
  {
    Forecast_Schedule__c scheduleToDelete = [ SELECT Id FROM Forecast_Schedule__c WHERE Id = :scheduleId ];
    delete scheduleToDelete;

    return scheduleToDelete;
  }
}