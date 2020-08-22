/******************************************
//Created By: Gram Bischof
//Last Modified by: Gram Bischof {2/25/2020}
//Description: Controller class for ProductScheduleForecastComp
//Test class : ProductScheduleForecastControllerTest
*******************************************/
public with sharing class ProductScheduleForecastController 
{
    @AuraEnabled
    public static List<Series> getForecastData(String opportunityRecordId, List<String> products) {
        List<Product_Schedule__c> prodSchList = [SELECT Month_Number__c, New_Business_Forecast_Amount__c , MRR__c , Opportunity_Product__r.Name
                                                 FROM Product_Schedule__c
                                                 WHERE Opportunity_Product__r.Opportunity__c=:opportunityRecordId
                                                 AND Opportunity_Product__r.Name IN:products and recordtype.developername !='Compensable_Forecast' 
                                                 ORDER BY Month_Number__c];
        
        List<Series> seriesList = new List<Series>();
        System.debug(' TTTTT '+products.contains('Total'));
        if(!products.contains('Total')) {
            seriesList.addAll(prepareChart('New_Business_Forecast_Amount__c', 'column', prodSchList));
            seriesList.addAll(prepareChart('MRR__c', 'spline', prodSchList));
        } else {
            seriesList.addAll(prepareTotalChart('New_Business_Forecast_Amount__c', 'column', prodSchList));
            //seriesList.addAll(prepareTotalMRRChart('MRR__c', 'spline', prodSchList));
        }
        
        return seriesList;
    }
    @AuraEnabled
    public static List<ProductOption> getProductData(String opportunityRecordId) {
        List<ProductOption> productList = new List<ProductOption>();
        Set<String> productSet = new Set<String>();
        for(Product_Schedule__c prodSch : [SELECT Opportunity_Product__r.Name
                                           FROM Product_Schedule__c
                                           WHERE Opportunity_Product__r.Opportunity__c=:opportunityRecordId])
        {
            if(!productSet.contains(prodSch.Opportunity_Product__r.Name)) {
                productList.add(new ProductOption(prodSch.Opportunity_Product__r.Name));
                productSet.add(prodSch.Opportunity_Product__r.Name);
            }
        }
        productList.add(new ProductOption('Total'));
        return productList;
    }
    private static List<Series> prepareChart(String countingField, String chartType, List<Product_Schedule__c> prodSchList) {
        Map<String, Decimal> groupedResults = new Map<String, Decimal>();
        List<String> monthList = new List<String>();
        for(Product_Schedule__c prodSch : prodSchList) {
            
            String key = prodSch.Month_Number__c+'#'+prodSch.Opportunity_Product__r.Name;
            Decimal sumAmount = 0.0;
            if(prodSch.get(countingField) != null) {
                sumAmount = (Decimal)prodSch.get(countingField);
            }
            if(groupedResults.containsKey(key)) {
                Decimal amount = groupedResults.get(key) + sumAmount;
                groupedResults.put(key, amount);
            } else {
                groupedResults.put(key, sumAmount);
            }
            if(!monthList.contains(''+prodSch.Month_Number__c)) {
                monthList.add(''+prodSch.Month_Number__c);
            }
        }
        
        Map<String, ForecastData> dataSetMap = new Map<String, ForecastData>();
        for(String monthNumberAndProduct : groupedResults.keySet()) {
            String monthNumber = monthNumberAndProduct.substringBefore('#');
            String productName = monthNumberAndProduct.substringAfter('#');
            System.debug(' Month key '+monthNumberAndProduct);
            ForecastData dataSet = new ForecastData();
            if(dataSetMap.containsKey(productName)) {
                dataSet = dataSetMap.get(productName);
                dataSet.add( monthNumber,groupedResults.get(monthNumberAndProduct) );
            } else {
                dataSet.add( monthNumber,groupedResults.get(monthNumberAndProduct) );
            }
            dataSetMap.put(productName, dataSet);
        }
        
        List<Series> seriesList = new List<Series>();
        for(String keyProduct : dataSetMap.keySet()) {
            Series seriesInst = new Series();
            seriesInst.name = keyProduct + (chartType == 'column' ? ' Forecast' : ' MRR');
            seriesInst.data = dataSetMap.get(keyProduct).dataList;
            seriesInst.type = chartType;
            seriesInst.category = dataSetMap.get(keyProduct).labelList;
            seriesList.add(seriesInst);
        }
        return seriesList;
    }
   /* private static List<Series> prepareTotalMRRChart(String countingField, String chartType, List<Product_Schedule__c> prodSchList) {
        Map<String, Decimal> groupedResults = new Map<String, Decimal>();
        for(Product_Schedule__c prodSch : prodSchList) {
            
            String key = String.valueOf(prodSch.Month_Number__c);
            Decimal sumAmount = 0.0;
            if(prodSch.get(countingField) != null) {
                sumAmount = (Decimal)prodSch.get(countingField);
            }
            if(groupedResults.containsKey(key)) {
                Decimal amount = groupedResults.get(key) + sumAmount;
                groupedResults.put(key, amount);
            } else {
                groupedResults.put(key, sumAmount);
            }
        }
        
        ForecastData dataSet = new ForecastData();
        Map<String, ForecastData> dataSetMap = new Map<String, ForecastData>();
        List<String> monthList = new List<String>();
        for(String monthNumber : groupedResults.keySet()) {
            if(dataSetMap.containsKey(monthNumber)) {
                dataSet = dataSetMap.get(monthNumber);
                dataSet.add( monthNumber,groupedResults.get(monthNumber) );
            } else {
                dataSet.add( monthNumber,groupedResults.get(monthNumber) );
            }
            if(!monthList.contains(monthNumber)) {
                monthList.add(monthNumber);
            }
        }
        dataSetMap.put('Total', dataSet);
        List<Series> seriesList = new List<Series>();
        for(String keyProduct : dataSetMap.keySet()) {
            Series seriesInst = new Series();
            seriesInst.name = keyProduct + (chartType == 'column' ? ' Forecast' : ' MRR');
            seriesInst.data = dataSetMap.get(keyProduct).dataList;
            seriesInst.type = chartType;
            seriesInst.category = monthList;
            seriesList.add(seriesInst);
        }
        return seriesList;
    }*/
    private static List<Series> prepareTotalChart(String countingField, String chartType, List<Product_Schedule__c> prodSchList) {
        Map<String, Decimal> groupedResults = new Map<String, Decimal>();
        for(Product_Schedule__c prodSch : prodSchList) {
            
            String key = prodSch.Month_Number__c+'#'+prodSch.Opportunity_Product__r.Name;
            Decimal sumAmount = 0.0;
            if(prodSch.get(countingField) != null) {
                sumAmount = (Decimal)prodSch.get(countingField);
            }
            if(groupedResults.containsKey(key)) {
                Decimal amount = groupedResults.get(key) + sumAmount;
                groupedResults.put(key, amount);
            } else {
                groupedResults.put(key, sumAmount);
            }
        }
        
        Map<String, ForecastData> dataSetMap = new Map<String, ForecastData>();
        List<String> productList = new List<String>();
        
        for(String monthNumberAndProduct : groupedResults.keySet()) {
            String monthNumber = monthNumberAndProduct.substringBefore('#');
            String productName = monthNumberAndProduct.substringAfter('#');
            System.debug(' Month key '+monthNumberAndProduct);
            ForecastData dataSet = new ForecastData();
            if(dataSetMap.containsKey(productName)) {
                dataSet = dataSetMap.get(productName);
                dataSet.add( productName, monthNumber, groupedResults.get(monthNumberAndProduct) );
            } else {
                dataSet.add( productName, monthNumber, groupedResults.get(monthNumberAndProduct) );
            }
            if(!productList.contains(monthNumber)) {
                productList.add(monthNumber);
            }
            dataSetMap.put(productName, dataSet);
        }
        
        Map<String, Series> seriesMap = new Map<String, Series>();
        for(String monthNumberAndProduct : groupedResults.keySet()) {
            Series seriesInst = new Series();
            seriesInst.name = monthNumberAndProduct.substringAfter('#');
            seriesInst.type = chartType;
        }
        
        List<Series> seriesList = new List<Series>();
        for(String keyProduct : dataSetMap.keySet()) {
            Series seriesInst = new Series();
            
            //Add on Jan 29,2020
            List<Decimal> theDataList = dataSetMap.get(keyProduct).dataList;
            Integer totalProductForecast = 0;
            for(Decimal amount : theDataList){
                totalProductForecast = totalProductForecast + Integer.valueof(amount);
            }
            List<String> args = new String[]{'0','number','###,###,##0.00'};
                String resultCurrency = String.format(totalProductForecast.format(), args);
            //
            //use Here
            seriesInst.name = keyProduct.substringAfter('#')+' (Product '+keyProduct.substringBefore('#')+' - $'+resultCurrency +')';
            seriesInst.data = dataSetMap.get(keyProduct).dataList;
            seriesInst.type = chartType;
            if(keyProduct.substringBefore('#') == 'SendGrid: OnGoing Services')seriesInst.color = '#52B5DE';
            else if(keyProduct.substringBefore('#') == 'SendGrid: Add-Ons')seriesInst.color = '#E76331';
            else if(keyProduct.substringBefore('#') == 'SendGrid: ISTP Services')seriesInst.color = '#FFB539';
            else if(keyProduct.substringBefore('#') == 'SendGrid: Expert Services')seriesInst.color = '#52A57B';
            else if(keyProduct.substringBefore('#') == 'SendGrid: Marketing Campaigns')seriesInst.color = '#4AD6D6';
            else if(keyProduct.substringBefore('#') == 'SendGrid: Email Infrastructure')seriesInst.color = '#E784B5';
            else if(keyProduct.substringBefore('#') == 'SendGrid: EASE')seriesInst.color = '#F79452';
            else if(keyProduct.substringBefore('#') == 'PSTN connectivity')seriesInst.color = '#6BCE52';
            else if(keyProduct.substringBefore('#') == 'Flex')seriesInst.color = '#F7D639';
            else if(keyProduct.substringBefore('#') == 'Long Code Carrier Fees')seriesInst.color = '#9473EF';
            else if(keyProduct.substringBefore('#') == 'Programmable Wireless')seriesInst.color = '#3296ED';
            else if(keyProduct.substringBefore('#') == 'Programmable Messaging')seriesInst.color = '#77B9F2';
            else if(keyProduct.substringBefore('#') == 'Numbers')seriesInst.color = '#9D53F2';
            else if(keyProduct.substringBefore('#') == 'Short Code')seriesInst.color = '#C398F5';
            else if(keyProduct.substringBefore('#') == 'Expert Services')seriesInst.color = '#26ABA4';
            else if(keyProduct.substringBefore('#') == 'Marketplace')seriesInst.color = '#4ED4CD';
            else if(keyProduct.substringBefore('#') == 'Elastic SIP Trunking')seriesInst.color = '#FACA9B';
            else if(keyProduct.substringBefore('#') == 'Support')seriesInst.color = '#CD86BC';
            else if(keyProduct.substringBefore('#') == 'Engagement Cloud - Software')seriesInst.color = '#2A2396';
            else if(keyProduct.substringBefore('#') == 'Programmable Fax')seriesInst.color = '#762F3A';
            else if(keyProduct.substringBefore('#') == 'Lookup')seriesInst.color = '#CE6716';
            else if(keyProduct.substringBefore('#') == 'Messaging - Software')seriesInst.color = '#F4284E';
            else if(keyProduct.substringBefore('#') == 'Twilio Editions')seriesInst.color = '#613102';
            else if(keyProduct.substringBefore('#') == 'Programmable Video')seriesInst.color = '#D19214';
            else if(keyProduct.substringBefore('#') == 'Voice - Software')seriesInst.color = '#76DED9';
            else if(keyProduct.substringBefore('#') == 'Programmable Voice')seriesInst.color = '#E2CE7D';
            else if(keyProduct.substringBefore('#') == 'Authy - Software')seriesInst.color = '#F598A7';
            else if(keyProduct.substringBefore('#') == 'Authy - Voice/SMS')seriesInst.color = '#F56580';
            else if(keyProduct.substringBefore('#') == 'Verify')seriesInst.color = '#61054F';
            else if(keyProduct.substringBefore('#') == 'IVR Bundle')seriesInst.color = '#006699';
            else if(keyProduct.substringBefore('#') == 'Twilio Pay')seriesInst.color = '#F0E442';
            else seriesInst.color = '#0A611B';
            //seriesInst.stack = keyProduct.substringAfter('#');
            seriesInst.category = productList;
            seriesList.add(seriesInst);
        }
        return seriesList;
    }
    
    public class ForecastData {
        @AuraEnabled
        public List<String> labelList;
        @AuraEnabled
        public List<String> monthList;
        @AuraEnabled
        public List<Decimal> dataList;
        public List<String> labelNameList = new List<String>{'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
                
                public ForecastData() {
                    labelList = new List<String>();
                    dataList = new List<Decimal>();
                    monthList = new List<String>();
                }
        
        public void add(String label, Decimal data) {
            labelList.add(label);
            dataList.add(data);
        }
        public void add(String label, String monthNumber, Decimal data) {
            labelList.add(label);
            dataList.add(data);
            monthList.add(monthNumber);
        }
    }
    public class Series {
        @AuraEnabled
        public String name;
        @AuraEnabled
        public List<String> category;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String yAxis;
        @AuraEnabled
        public String stack;
        @AuraEnabled
        public object data;
        @AuraEnabled
        public String color;
    }
    public class ProductOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        public ProductOption(String productName) {
            this.label = productName;
            this.value = productName;
        }
    }
}