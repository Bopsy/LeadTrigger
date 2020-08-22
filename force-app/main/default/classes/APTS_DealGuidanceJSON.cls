public class APTS_DealGuidanceJSON{

    public Boolean HidePrice{get;set;}
    public Boolean HidePercentile{get;set;}
    public List<Entries> Entries{get;set;}
    public List<DimensionValues> DimensionValues{get;set;}
    public List<DimensionValues> DimensionLabels{get;set;}
    public List<CustomProps> CustomProps{get;set;}

    public class DimensionValues {
    }

    public class Entries{
        public Integer Sequence{get;set;}
        public String Rating{get;set;}
        public String RangeName{get;set;}
        public Double PriceTo{get;set;}
        public Double PriceFrom{get;set;}
        public Double PercentileTo{get;set;}
        public Double PercentileFrom{get;set;}
        public String MeasureType{get;set;}
        public Boolean IsItemRating{get;set;}
        public Boolean HidePrice{get;set;}
        public Boolean HidePercentile{get;set;}
        public List<DimensionValues> DimensionValues{get;set;}
        public List<DimensionValues> DimensionLabels{get;set;}
        public String ColorCode{get;set;}
        public String cssclass{get;set;}
        public String customPriceToFormatted{get;set;}
        public String customPriceFromFormatted{get;set;}
    }

    public class CustomProps {
        public String ValueType;
        public String Value;
        public Object parentSO;
        public String Name;
        public Boolean isEvaluated;
        public Object ctxFieldName;
        public Object contextSO;
        public Object childSO;
        public Object childFilterName;
        public Object childFieldName;
    }
    
    public static APTS_DealGuidanceJSON parse(String json) {
        return (APTS_DealGuidanceJSON ) System.JSON.deserialize(json,APTS_DealGuidanceJSON.class);
    }
}