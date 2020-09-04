public class CIFUtility {
    
    @testVisible
    private List<String> getOperators(String Logic){
        List<String> operators = new List<String>();
        for(String token : logic.split(' ')){
            if(token.trim() == 'OR' || token.trim() == 'AND') operators.add(token.trim());
        }
        return operators;
    }
    
    /*@testVisible
    private List<Boolean> getOperands(Sobject obj, String logic, Map<String,CIF_Object_Filters__mdt> filters){
        List<Boolean> operands = new List<Boolean>();
        for(String token : logic.split(' ')){
            if(filters.containsKey(token.trim())) operands.add(evaluateRecord(obj, filters.get(token.trim())));
        }
        return operands;
    }
    
    public Boolean criteriaLogic(List<Boolean> operands, List<String> operators){
        if(operands.isEmpty() || operators.isEmpty() || operands.size()-1 != operators.size()) return false;
        if(operands.size() == 1) return operands[0];
        Boolean left = operands.remove(0);
        String operator = operators.remove(0);
        return logicEvaluation(left,operator,criteriaLogic(operands,operators));
    }
    
    public Boolean logicEvaluation(Boolean leftOperand, String operator, Boolean rightOperand){
        if(operator == 'OR') return leftOperand || rightOperand;
        if(operator == 'AND') return leftOperand && rightOperand;
        return false;
    }
    
    public Boolean evaluateRecord(Sobject obj, CIF_Object_Filters__mdt filter){
        return meetsCriteria(obj.get(filter.Field__c),filter.Field_Type__c,filter.Condition__c,filter.Value__c);
    }
    
    public Boolean meetsCriteria(Object leftoperand, String leftOperandType,String operator, Object rightoperand){
        
        switch on operator{
            when 'equal' {
                return leftoperand == rightoperand;
            }
            when 'not equal to' {
                return leftoperand != rightoperand;
            }
            when 'starts with'{
                if(leftOperandType != 'Text') return false;
                return ((String)leftOperand).contains((String)rightOperand);
            }
            when 'contains'{
                if(leftOperandType != 'Text') return false;
                return ((String)leftOperand).contains((String)rightOperand);
            }
            when 'does not contain'{
                if(leftOperandType != 'Text') return false;
                return !((String)leftOperand).contains((String)rightOperand);
            }
            when 'less than'{
                if(leftOperandType == 'Number') return (Decimal)leftOperand < (Decimal)rightOperand;
                if(leftOperandType == 'Date') return (Date)leftOperand < (Date)rightOperand;
                if(leftOperandType == 'DateTime') return (DateTime)leftOperand < (DateTime)rightOperand;
                if(leftOperandType == 'Time') return (Time)leftOperand < (Time)rightOperand;
                return false;
            }
            when 'less or equal'{
                if(leftOperandType == 'Number') return (Decimal)leftOperand <= (Decimal)rightOperand;
                if(leftOperandType == 'Date') return (Date)leftOperand <= (Date)rightOperand;
                if(leftOperandType == 'DateTime') return (DateTime)leftOperand <= (DateTime)rightOperand;
                if(leftOperandType == 'Time') return (Time)leftOperand <= (Time)rightOperand;
                return false;
            }
            when 'greater than'{
                if(leftOperandType == 'Number') return (Decimal)leftOperand > (Decimal)rightOperand;
                if(leftOperandType == 'Date') return (Date)leftOperand > (Date)rightOperand;
                if(leftOperandType == 'DateTime') return (DateTime)leftOperand > (DateTime)rightOperand;
                if(leftOperandType == 'Time') return (Time)leftOperand > (Time)rightOperand;
                return false;
            }
            when 'greater or equal'{
                if(leftOperandType == 'Number') return (Decimal)leftOperand >= (Decimal)rightOperand;
                if(leftOperandType == 'Date') return (Date)leftOperand >= (Date)rightOperand;
                if(leftOperandType == 'DateTime') return (DateTime)leftOperand >= (DateTime)rightOperand;
                if(leftOperandType == 'Time') return (Time)leftOperand >= (Time)rightOperand;
                return false;
            }
        }
        return false;
    }*/
    
}