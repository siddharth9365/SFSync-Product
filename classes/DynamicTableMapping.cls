public class DynamicTableMapping {
    public Dynamic_Table_Mapping__c tableMapping{get;set;}
    public Dynamic_Table_Mapping__c dbTableMapping{get;set;}
    public List<Dynamic_Table_Mapping__c> dynamicMappingList;
    public List<String> fieldList;
    Map<String,Schema.SObjectType> globalSchemaList = Schema.getGlobalDescribe();
    public String jsonData{get;set;}
    
    public DynamicTableMapping(){
        tableMapping = new Dynamic_Table_Mapping__c();
        dbTableMapping = new Dynamic_Table_Mapping__c();
        jsonData ='';
        //addSfTableNames();
    }
    
    public LIST<Dynamic_Table_Mapping__c> getMappingList(){
        List<Dynamic_Table_Mapping__c> mappingList = [SELECT Record_Type_Id__c,SfFieldName__c,SfLookupName__c,SfTableName__c,DbFieldName__c,DbLookupName__c,DbTableName__c FROM Dynamic_Table_Mapping__c];
        return mappingList;
    }
    
    public List<SelectOption> getSfTableNameList(){
        List<SelectOption> sfTableNameList = new List<SelectOption>();
        SfTableNameList.add(new SelectOption('', '-------please select-------'));
        List<String> objectNames = new List<String>(globalSchemaList.keySet());
        objectNames.sort();
        tableMapping.SfTableName__c = objectNames.get(0);
        for(String name : objectNames){
            if(!name.containsignorecase('history') && !name.containsignorecase('tag')&&
               !name.containsignorecase('share') && !name.containsignorecase('feed')){
                   sfTableNameList.add(new SelectOption(name, name));
               }
        }
        return sfTableNameList;
    }

    public List<SelectOption> getDbTableNameList(){
        List<SelectOption> dbTableNameList = new List<SelectOption>();
        dbTableNameList.add(new SelectOption('', '-------please select-------'));
        List<aggregateResult> resultList = [SELECT DbTableName__c FROM Dynamic_Table_Mapping__c GROUP BY DbTableName__c];
        for(aggregateResult dynamictable : resultList){
             dbTableNameList.add(new SelectOption(String.valueOf(dynamictable.get('DbTableName__c')),String.valueOf(dynamictable.get('DbTableName__c'))));
        }
        return dbTableNameList;
    }
    
    public List<SelectOption> getSfFieldNamesList(){
        List<SelectOption> sfFieldNameList = new List<SelectOption>();
        if(tableMapping.SfTableName__c!=null){
            Map <String, Schema.SObjectField> fieldMap = globalSchemaList.get(tableMapping.SfTableName__c).getDescribe().fields.getMap();
            for(String key : fieldMap.keySet()){
                sfFieldNameList.add(new SelectOption(key,key));    
            }
        }
        return sfFieldNameList;
    }

    public List<SelectOption> getDbFieldNamesList(){
        List<SelectOption> dbFieldNameList = new List<SelectOption>();
        fieldList = new List<String>();
        dbFieldNameList.add(new SelectOption('', '-------please select-------'));
        dynamicMappingList = getMappingList();
        Map<String,List<String>> dynamictableMap = new Map<String,List<String>>();
        for(Dynamic_Table_Mapping__c dynamicTable : dynamicMappingList){
            List<String> newFIeldList = new List<String>();
            if(!dynamictableMap.containsKey(dynamicTable.DbTableName__c)){
                newFIeldList.add(dynamicTable.DbFieldName__c);
                dynamictableMap.put(dynamicTable.DbTableName__c, newFIeldList);
            }else{
                newFIeldList = dynamictableMap.get(dynamicTable.DbTableName__c);
                newFIeldList.add(dynamicTable.DbFieldName__c);
                dynamictableMap.put(dynamicTable.DbTableName__c,newFIeldList);
            }
        }

    System.debug('hi : '+dynamictableMap.get(dbTableMapping.DbTableName__c));
    if(dynamictableMap.get(dbTableMapping.DbTableName__c)!=null){
        for(String fieldName : dynamictableMap.get(dbTableMapping.DbTableName__c)){
            dbFieldNameList.add(new SelectOption(fieldName,fieldName));
            fieldList.add(fieldName);
        }
    }
    return dbFieldNameList;
    }
    public void saveMapping(){
        insert tableMapping;
        tableMapping = new Dynamic_Table_Mapping__c();
    }

    public void generateJSON(){
        List<Map<String,Object>> fieldValueMapList = new List<Map<String,Object>>();
        Map<String,Object> tempFieldMap;
        for(String field : fieldList){
            tempFieldMap = new Map<String,Object>();
            tempFieldMap.put('fieldValue', '');
            tempFieldMap.put('fieldName', field);
            fieldValueMapList.add(tempFieldMap);
        }
        List<Object> tableDataList = new List<Object>();
        tableDataList.add(fieldValueMapList);
        Map<String,Object> finalTableMap = new Map<String,Object>();
        finalTableMap.put('tableData', tableDataList);
        finalTableMap.put('uniqueFieldName', dbTableMapping.DbFieldName__c);
        finalTableMap.put('tableName', dbTableMapping.DbTableName__c);
        jsonData = JSON.serializePretty(finalTableMap);
        System.debug(jsonData);
    }
    
}