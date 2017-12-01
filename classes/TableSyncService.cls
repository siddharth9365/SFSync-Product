public class TableSyncService {
    
    public Id getRecordTypeId(String tableName){
        Id recordTypeId;
        String developerName = [SELECT Record_Type_Dev_Name__c FROM Record_Type_Setting__mdt WHERE Db_Table_Name__c =: tableName LIMIT 1].Record_Type_Dev_Name__c;
        recordTypeId=[SELECT Id FROM RecordType WHERE DeveloperName =: developerName limit 1].Id; 
        return recordTypeId;
    }
}