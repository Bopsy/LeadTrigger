global class BatchFieldSalesForecast implements Database.Batchable<SObject>, Schedulable, Database.Stateful {

  public String errors;

  global BatchFieldSalesForecast() {
    this.errors = '';
  }

  global Database.QueryLocator start( Database.BatchableContext bc ) {
    return Database.getQueryLocator([ SELECT Id, Forecast_Owner__c, Manager_Forecast__r.Forecast_Owner__c,
                                        Start_Date__c, Stage__c
                                      FROM Field_Sales_Forecast__c ]);
  }

  global void execute( Database.BatchableContext bc, List<Field_Sales_Forecast__c> forecasts ) {
    FieldSalesForecast.disableFuture = true;

    Set<Id> ownerIds = new Set<Id>();
    for( Field_Sales_Forecast__c aForecast : forecasts ) {
      ownerIds.add( aForecast.Forecast_Owner__c );
    }

    Map<Id, User> ownersWithManagers = new Map<Id, User>([ SELECT Id, ManagerId FROM User WHERE Id IN :ownerIds ]);
    List<Field_Sales_Forecast__c> forecastsToRealign = new List<Field_Sales_Forecast__c>();
    Set<Id> forecastsToRecalculate = new Set<Id>();
    for( Field_Sales_Forecast__c aForecast : forecasts ) {
      Id currentManager = ownersWithManagers.get( aForecast.Forecast_Owner__c ).ManagerId;
      Id managerOnForecast = aForecast.Manager_Forecast__r.Forecast_Owner__c;

      if( managerOnForecast != currentManager ) {
        if( aForecast.Manager_Forecast__c != NULL ) {
          forecastsToRecalculate.add( aForecast.Manager_Forecast__c );
        }

        aForecast.Manager_Forecast__c = NULL;
        forecastsToRealign.add( aForecast );
      }
    }

    FieldSalesForecast.findOrCreateManagerForecasts( forecastsToRealign );
    List<Database.SaveResult> updateResults = Database.update( forecastsToRealign, false );
    for( Database.SaveResult aResult : updateResults ) {
      if( !aResult.isSuccess() ) {
        for( Database.Error anError : aResult.getErrors() ) {
          this.errors += aResult.getId() + ': ' + anError.getMessage() + '\n';
        }
      }
    }

    List<Field_Sales_Forecast__c> managerForecasts = new List<Field_Sales_Forecast__c>();
    for( Id aManagerForecastId : forecastsToRecalculate ) {
      Field_Sales_Forecast__c managerForecast = new Field_Sales_Forecast__c();
      managerForecast.Id = aManagerForecastId;
      managerForecasts.add( managerForecast );

      // zero out submanager fields in case there are no longer and subordinates remaining
      managerForecast.Submanager_Forecast_Total__c = 0.0;
      managerForecast.Submanager_Contract_Total__c = 0.0;
      managerForecast.Submanager_Sales_Current_Quarter__c = 0.0;
      managerForecast.Submanager_Modified_Forecast__c = 0.0;
      managerForecast.Submanager_Modified_Contract__c = 0.0;
      managerForecast.Submanager_Modified_Previous_Quarter__c = 0.0;
    }
    List<Database.SaveResult> zeroOutResults = Database.update( managerForecasts, false );
    for( Database.SaveResult aResult : zeroOutResults ) {
      if( !aResult.isSuccess() ) {
        for( Database.Error anError : aResult.getErrors() ) {
          this.errors += aResult.getId() + ': ' + anError.getMessage() + '\n';
        }
      }
    }

    List<Field_Sales_Forecast__c> childForecastsToUpdate = [ SELECT Id, Manager_Forecast__c FROM Field_Sales_Forecast__c WHERE Manager_Forecast__c IN :forecastsToRecalculate ];
    FieldSalesForecast.updateManagerForecasts( childForecastsToUpdate );
  }

  global void finish( Database.BatchableContext bc) {
    if( !String.isBlank( this.errors ) ) {
      System.debug(LoggingLevel.ERROR, this.errors);

      AsyncApexJob thisJob = [ SELECT Id, CreatedBy.Email, Status FROM AsyncApexJob WHERE Id = :bc.getJobId() ];
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
      List<String> toAddresses = new List<String>{ thisJob.CreatedBy.Email };
      mail.setToAddresses( toAddresses );
      mail.setSubject( 'Field Sales Forecast Manager True-Up ' + thisJob.Status);
      mail.setPlainTextBody( 'Errors:\n' + this.errors );
      Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{ mail } );
    }
  }

  global void execute( SchedulableContext sc ) {
    Database.executeBatch( new BatchFieldSalesForecast(), 200 );
  }
}