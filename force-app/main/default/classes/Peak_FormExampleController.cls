/**
 * Created by kentheberling on 7/14/17.
 */

public with sharing class Peak_FormExampleController {

    @AuraEnabled
    public static Peak_Response handleSubmit(String inputText){
        Peak_Response peakResponse = new Peak_Response();

        // Just show the messages to user in either case
        peakResponse.success = false;

        if (inputText == 'Hello'){
            peakResponse.messages.add('Congrats, you typed "Hello"');
        } else {
            peakResponse.messages.add('You did not type "Hello"');
        }

        return peakResponse;
    }
}