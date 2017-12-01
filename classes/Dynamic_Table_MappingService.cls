@RestResource(urlMapping='/insertAndUpdateProduct/*')
global class Dynamic_Table_MappingService {
    static Map<String,String> dbRecordTypeNameMap = new Map<String,String>();
    static Map<String,Id> recordNameIdMap = new Map<String,Id>();
    global static void gettingRecordTypes(){
    	List<RecordTypeSetting__c> recordTypeSettingList = [SELECT Db_TableName__c,Record_Type_Name__c FROM RecordTypeSetting__c];
    	List<String> recordTypeNameList = new List<String>();
    	for(RecordTypeSetting__c recordTypeSetting : recordTypeSettingList){
    		dbRecordTypeNameMap.put(recordTypeSetting.Db_TableName__c,recordTypeSetting.Record_Type_Name__c);
    		recordTypeNameList.add(recordTypeSetting.Record_Type_Name__c);
    	}
    	
    	List<RecordType> recordTypeList = [SELECT Id,Name FROM RecordType WHERE Name IN :recordTypeNameList];
    	for(RecordType recordType : recordTypeList){
    		recordNameIdMap.put(recordType.Name,recordType.Id);
    	}
    	System.debug('dcbjkdcbdj '+ recordNameIdMap);
    }
    //For getting record type id of table
    global static Id getRecordTypeId(String tableName){
        gettingRecordTypes();
        Id recordTypeId = recordNameIdMap.get(dbRecordTypeNameMap.get(tableName));
        System.debug('id : '+recordNameIdMap + dbRecordTypeNameMap);
        return recordTypeId;
    }
    
    //for getting DB to SF fields mapping
    global static Map<String,Object> getDbToSfFieldMapping(List<Dynamic_Table_Mapping__c> mappingList){
        Map<String,Object> sfObjectsMap = new Map<String,Object>();
        
        for(Dynamic_Table_Mapping__c dynamicTemp : mappingList){
            sfObjectsMap.put(dynamicTemp.DbFieldName__c, dynamicTemp.SfFieldName__c);
        }
        
        return sfObjectsMap;
    }
    
    //For getting Dynamic_Table_Mapping List
    global static List<Dynamic_Table_Mapping__c> getDynamic_Table_MappingListByDB(String DbTableName){
        List<Dynamic_Table_Mapping__c> sfObjectNamesList = [SELECT DbLookupName__c,isRecordType__c,SfLookupName__c,DbFieldName__c,DbTableName__c,SfFieldName__c,SfTableName__c FROM Dynamic_Table_Mapping__c WHERE DbTableName__c =: DbTableName];
        return sfObjectNamesList;
    }
    
    global static Map<String,Object> getLookupFields(List<Dynamic_Table_Mapping__c> mappingList){
        Map<String,Object> sfObjectsMap = new Map<String,Object>();
        Map<String,String> sfLookupMap = new Map<String,String>();
        Map<String,String> dbLookupMap = new Map<String,String>();
        Map<String,Boolean> recordTypeMap = new Map<String,Boolean>();
        
        for(Dynamic_Table_Mapping__c dynamicTemp : mappingList){
            sfLookupMap.put(dynamicTemp.DbFieldName__c, dynamicTemp.SfLookupName__c);
            dbLookupMap.put(dynamicTemp.DbFieldName__c, dynamicTemp.DbLookupName__c);
            recordTypeMap.put(dynamicTemp.DbFieldName__c, dynamicTemp.isRecordType__c);
        }
        
        sfObjectsMap.put('sfLookupMap', sfLookupMap); 
        sfObjectsMap.put('dbLookupMap', dbLookupMap);
        sfObjectsMap.put('recordTypeMap', recordTypeMap);
        
        return sfObjectsMap;
    }
    
    @HttpPost
    global static void insertAndUpdate(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        List<Map<String,String>> responseList = new List<Map<String,String>>();
        try{
            System.debug(req);
            Map<String, object> restValues = RestfulServiceUtils.parseJsonFromRequest(req);
            List<Object> tableDataMultiList = (List<Object>)restValues.get('tableData');
            String DbTableName = (String)restValues.get('tableName');
            String uniqueColummName = (String)restValues.get('uniqueFieldName');
            List<Dynamic_Table_Mapping__c> sfObjectNamesList = getDynamic_Table_MappingListByDB(DbTableName);
            
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sfObjectNamesList.get(0).SfTableName__c);       
            
            Schema.DescribeSObjectResult sobjResult = targetType.getDescribe();
            SObject obj;   
            String className = sobjResult.getName();
            Dynamic_Mapping_SObject upsertDynamicSobject = new Dynamic_Mapping_SObject(className);
            
            Id recordTypeId = getRecordTypeId(DbTableName);
            Map<String,Object> mapSfObjectList = getDbToSfFieldMapping(sfObjectNamesList);
            Map<String,Object> sfObjectsMap = getLookupFields(sfObjectNamesList);
            Map<String,String> sfLookupMap = (Map<String,String>)sfObjectsMap.get('sfLookupMap');
            Map<String,String> dbLookupMap = (Map<String,String>)sfObjectsMap.get('dbLookupMap');
            Map<String,Boolean> recordTypeStatusMap = (Map<String,Boolean>)sfObjectsMap.get('recordTypeMap');
            Map<String, Schema.SObjectField> schemaFieldMap = sobjResult.fields.getMap();
            List<String> externalIdsList = new List<String>();
            
            for(Object tableData : tableDataMultiList){
                List<Object> tableDataList = (List<Object>)tableData; 
                obj = targetType.newSObject();
                String externalId = null;
                String tempRecordType = null;
                for(Object mapdata : tableDataList){
                    
                    Map<String,Object> tableDataMap = (Map<String,Object> )mapdata;
                    String fieldName = (String)tableDataMap.get('fieldName');
                    Object value = tableDataMap.get('fieldValue');
                    //System.debug('*************************'+(String)mapSfObjectList.get(fieldName));
                    if(schemaFieldMap.get((String)mapSfObjectList.get(fieldName))!=null){
                        System.debug('************* '+fieldName);
                        if(fieldName.equalsIgnoreCase(uniqueColummName)){   
                            externalId = DbTableName+(String)value;
                            obj.put('External_Field_Id__c',externalId);
                        } 
                        
                        if(fieldName.equalsIgnoreCase('STATUS') && ((String)value).equalsIgnoreCase('D')){
                            externalIdsList.add(externalId);
                        }
                        
                        Schema.DisplayType fieldType = schemaFieldMap.get((String)mapSfObjectList.get(fieldName)).getDescribe().getType();
                        if(value!=null && String.valueOf(value).trim() != ''){
                            if(fieldType == Schema.DisplayType.DateTime){
                                obj.put(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)),DateTime.valueOf(value).format('yyyy-MM-dd HH:mm:ss'));
                            }else if(fieldType == Schema.DisplayType.Date){
                                Date datevalue = Date.valueOf(value);
                                obj.put(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)),DateTime.newInstance(datevalue.year(),datevalue.month(),datevalue.day()).format('yyyy-MM-dd'));
                            }else if(fieldType  == Schema.DisplayType.Integer){
                                obj.put(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)),Integer.valueOf(value));
                            }else if(fieldType  == Schema.DisplayType.CURRENCY){
                                obj.put(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)),Double.valueOf(value));
                            }else if(fieldType  == Schema.DisplayType.Double){
                                obj.put(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)),Double.valueOf(value));
                            }else if(fieldType  == Schema.DisplayType.REFERENCE) {
                                sObject sObj = Schema.getGlobalDescribe().get(sfLookupMap.get(fieldName)).newSObject();
                                sObj.put('External_Field_Id__c',dbLookupMap.get(fieldName)+(String)value);
                                obj.putSObject(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)), sObj);
                                System.debug(sObj+ 'sobj : '+obj);
                                //obj.putSobject(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)),string.valueOf(value));
                            }else{
                                obj.put(schemaFieldMap.get((String)mapSfObjectList.get(fieldName)),string.valueOf(value));
                                if(recordTypeStatusMap.get(fieldName)){
                                	tempRecordType = getRecordTypeId((String)value);
                                }
                            }
                        }
                        
                    }
                    
                }
                if(recordTypeId!=null || tempRecordType!=null){
                    if(tempRecordType!=null){
                        obj.put('recordtypeid', tempRecordType);
                        tempRecordType = null;
                    }else{
                        obj.put('recordtypeid', recordTypeId);
                    }
                    //recordTypeId = null;
                }   
                System.debug('test obj'+obj);
                upsertDynamicSobject.addSfObject(obj);
            }    
            responseList=upsertDynamicSobject.upsertSobjects();
            System.debug('list of ids : '+externalIdsList);
            String query = 'select id from '+sfObjectNamesList.get(0).SfTableName__c+' WHERE External_Field_Id__c IN :externalIdsList and External_Field_Id__c != null';
            List<SObject> deleteList = Database.query(query);
            delete deleteList;            
        }catch(Exception e){
            Log__c lg = new Log__c();
            lg.Class_Name__c = 'Dynamic_Table_MappingService';
            lg.Exception_Message__c = e.getStackTraceString() + e.getMessage();
            lg.Method_Name__c = 'insertAndUpdate';
            lg.Input_Data__c = req.requestBody.toString();
            insert lg;
            Map<String,String> exceptionResultMap = new Map<String,String>();
            exceptionResultMap.put('Status','false');
            exceptionResultMap.put('error',e.getStackTraceString()+e.getmessage());
            res.statusCode = 400;
        }
        Map<String,String> responseMap = new Map<String,String>();
        responseMap.put('Status', 'No Failures....');
        res.responseBody = RestfulServiceUtils.parseValToJson(responseList.size()==0?new List<Map<String,String>>{responseMap}:responseList);        
    }
    
}