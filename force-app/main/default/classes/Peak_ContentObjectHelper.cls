// Format various pieces of content as a Peak Content Object
// When to use this? When you're not querying an SObject directly. For example, if you have a custom wrapper class that you want to return in a Peak Response list, you will have to format using a helper method here
public with sharing class Peak_ContentObjectHelper {

    // Basic demo - create Peak Content Object from string
    Public Peak_ContentObject formatFromString(string objectName) {
        Peak_ContentObject peakContent = new Peak_ContentObject();
        peakContent.title = objectName;
        return peakContent;
    }

    // Other examples would be something like formatFromYourCustomObject
}