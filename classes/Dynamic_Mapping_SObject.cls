public class Dynamic_Mapping_SObject {
    Map<String,Schema.SObjectType> allObjectsMap;
    List<Product2> productObjectsList = new List<Product2>();
    List<User> userList = new List<User>();
    List<Account> accountList = new List<Account>();
    List<SObject> sobjList = new List<SObject>();
    
    String sfObjectName;
    
    //for initializing sobject table name
    public Dynamic_Mapping_SObject(String sfObjectName){
        this.sfObjectName = sfObjectName;
    }
    
    //For adding sobject in list for DML operation
    public void addSfObject(SObject sfObjectData){
        sobjList.add(sfObjectData);
        
    }
    
    //For getting status messages of database
    public List<Map<String,String>> getDMLStatusMessages(Database.UpsertResult [] cr){
        Map<String,String> successMap; 
        List<Map<String,String>> successList=new List<Map<String,String>>();
        Set<Id> setSuccessIds = new Set<Id>();
        
        for(Database.UpsertResult p : cr){
            successMap = new Map<String,String>();
            if(p.isSuccess()){
                // successMap.put('Status', 'success');
                // successMap.put('SfId', p.getId());
                // setSuccessIds.add(p.getId());
            }else{
                for(Database.Error er : p.getErrors()){
                    successMap.put('Error ', er.getMessage());
                }
                successMap.put('External Id :',p.getId() );
                successMap.put('Status', 'Fail');
                successList.add(successMap);
            }
            
        }
        
        return successList;
    }
    
    public Map<Object,Object> getLookupTableWithIds(Set<Object> referenceSet){
        Map<Object,Object> sobjectLookupMap = new Map<Object,Object>();
        for(Object referenceObj : referenceSet){
            Map<String, Sobject> externalIdMap = new Map<String, Sobject>();
            List<Schema.SObjectType> referenceType = (List<Schema.SObjectType>)referenceObj;
            //System.debug('refrence type : '+referenceType.get(0).getDescribe().getName());
            for(Sobject sobj : Database.query('SELECT External_Field_Id__c,Name from '+referenceType.get(0).getDescribe().getName())){
                externalIdMap.put(String.valueOf(sobj.get('External_Field_Id__c')), sobj);
            }
            System.debug('map of id:'+externalIdMap);
            sobjectLookupMap.put(referenceObj, externalIdMap);
        } 
        return sobjectLookupMap;
    }
    //For userting dynamic sobject via dynamic casting
    public List<Map<String,String>> upsertSobjects(){
        List<Map<String,String>> successList;
        String listSObjectTypeName = 'List<' + sfObjectName + '>';
        System.Type objType= Type.forName(listSObjectTypeName);
        List<SObject> recordsToUpsert = (List<SObject>) objType.NewInstance();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sfObjectName);       
        Schema.DescribeSObjectResult sobjResult = targetType.getDescribe();
        Map<String, Schema.SObjectField> schemaFieldMap = sobjResult.fields.getMap();
        Schema.SObjectField f;
        Map<String,object> referenceTypeMap = new Map<String,Object>();
        Map<String,String> lookupMap = new Map<String,String>();
        Set<Object> referenceSet = new Set<Object>();
        for(Schema.SObjectField field : schemaFieldMap.values()){
            Schema.DescribeFieldResult fieldResult = field.getDescribe();
            if('External_Field_Id__c'.equalsignorecase(fieldResult.getName())){
                f = field;
            }
            //System.debug('field Name : '+fieldResult.getName()+' field type : '+fieldResult.getType());
            if(fieldResult.getType() == Schema.DisplayType.REFERENCE){
                //System.debug('field Name1 : '+fieldResult.getName()+' field type1 : '+fieldResult.getType());
                referenceTypeMap.put(fieldResult.getRelationshipName(),fieldResult.getReferenceTo());
                lookupMap.put(fieldResult.getRelationshipName(), fieldResult.getName());
                //System.Type listType = Type.forName(String.valueof(fieldResult.getReferenceTo()));
                //System.debug('map : '+listType +' cxbchvbh '+ fieldResult.getReferenceTo());
                List<Schema.SObjectType> objectList = fieldResult.getReferenceTo(); 
                referenceSet.add(objectList);
                //List<Sobject> sobList = (List<Sobject>)listType.newInstance();
                //referenceSet.add(sobList); 
            }
        }
        Map<Object,Object> sobjectWithLookupMap = getLookupTableWithIds(referenceSet);
        //Map<String,Object> sobjectWithLookupMap = new Map<String,Object>();
        System.debug('test1qsqsssq : '+sobjList);
        for(SObject sobj : sobjList){
            Map<String, Object> fieldsToValueMap =sobj.getPopulatedFieldsAsMap();
            Map<String,Object> tempReferenceMap = new Map<String,Object>();
            for(String field : fieldsToValueMap.keySet()){
                if(referenceTypeMap.get(field)!=null){
                    //tempReferenceMap.put(field, fieldsToValueMap.get(field));
                    List<Schema.SObjectType> tempObjectList = (List<Schema.SObjectType>)referenceTypeMap.get(field);
                    Map<String,SObject> externalIdMap = (Map<String,SObject>)sobjectWithLookupMap.get(tempObjectList);
                    system.debug('extrnal map : '+externalIdMap.get(String.valueOf(((Sobject)fieldsToValueMap.get(field)).get('External_Field_Id__c'))));
                    if(externalIdMap.get(String.valueOf(((Sobject)fieldsToValueMap.get(field)).get('External_Field_Id__c')))==null){
                        System.debug('before : '+String.valueOf(fieldsToValueMap.get(field)));
                        sobj.putSObject(field, null);
                        System.debug('after : '+String.valueOf(fieldsToValueMap.get(field)));
                    }
                }
            }
            //sobjectWithLookupMap.put(String.valueOf(sobj.get('External_Field_Id__c')),tempReferenceMap);
        }
        recordsToUpsert.addAll(sobjList);
        
        Database.UpsertResult [] cr = Database.upsert(recordsToUpsert,f);
        successList = getDMLStatusMessages(cr); 
        return successlist;
    }
}