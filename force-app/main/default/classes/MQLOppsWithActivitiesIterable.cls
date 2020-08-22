global class MQLOppsWithActivitiesIterable implements Iterator<list<ActivityRecord>>{

   list<ActivityRecord> InnerList{get; set;}
   list<ActivityRecord> ListRequested{get; set;}

   Integer i {get; set;} 
   public Integer setPageSize {get; set;} 

   public MQLOppsWithActivitiesIterable(List<ActivityRecord> lstAccWr)
   {
       InnerList = new list<ActivityRecord >(); 
       ListRequested = new list<ActivityRecord >();     
       InnerList = lstAccWr;
       setPageSize = 5;
       i = 0; 
   }   

   global boolean hasNext(){ 
       if(i >= InnerList.size()) {
           return false; 
       } else {
           return true; 
       }
   } 
   
   global boolean hasPrevious(){ 
       system.debug('I am in hasPrevious' + i);
       if(i <= setPageSize) {
           return false; 
       } else {
           return true; 
       }
   }   

    global list<ActivityRecord > First()
    {
        ListRequested.clear();
        i=0;
        if((i + setPageSize) <= InnerList.size()){
            for(Integer j=0;j<setPageSize;j++){
                ListRequested.add(InnerList.get(j));
            }  
        } else{
            for(Integer j=0;j<InnerList.size();j++){
                ListRequested.add(InnerList.get(j));
            }      
        }
        return ListRequested;
    }
    
    global list<ActivityRecord > Last()
    {
        ListRequested.clear();
        if(math.mod(InnerList.size() , setPageSize) == 0){
            i = setPageSize * ((InnerList.size()/setPageSize)-1);
        } else if (math.mod(InnerList.size() , setPageSize) != 0){
            i = setPageSize * ((InnerList.size()/setPageSize));
        }
       
        for(Integer j=i;j<InnerList.size();j++){
            ListRequested.add(InnerList.get(j));
        }
        i= InnerList.size();
        return ListRequested;
    }
    
   global list<ActivityRecord > next(){       
       system.debug('i value is ' + i);
       ListRequested = new list<ActivityRecord >(); 
       integer startNumber;
       integer size = InnerList.size();
       if(hasNext())
       {  
           if(size <= (i + setPageSize))
           {
               startNumber = i;
               i = size;
           }
           else
           {
               i = (i + setPageSize);
               startNumber = (i - setPageSize);
           }
           
           system.debug('i value is =====' + i);
           system.debug('i value is 2==== ' + (i - setPageSize));
           
           for(integer start = startNumber; start < i; start++)
           {
               ListRequested.add(InnerList[start]);
           }
       } 
       return ListRequested;
   } 
   
   global list<ActivityRecord > previous(){      
       ListRequested = new list<ActivityRecord >(); 
       system.debug('i value is previous before =====' + i);
       integer size = InnerList.size(); 
       if(i == size)
       {
           if(math.mod(size, setPageSize) > 0)
           {    
               i = size - math.mod(size, setPageSize);
           }
           else
           {
               i = (size - setPageSize);
           } 
       }
       else
       {
           i = (i - setPageSize);
       }
       
       system.debug('i value is previous =====' + i);
       system.debug('i value is 2previous ==== ' + (i - setPageSize));
       
       for(integer start = (i - setPageSize); start < i; ++start)
       {
           ListRequested.add(InnerList[start]);
       } 
       return ListRequested;
   }   
}