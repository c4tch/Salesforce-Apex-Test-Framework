/**
 @Name: c_TestFactory.cls
 @TestedBy: Implementing in a test class
 @Description: TestFactory Framework base class; generates test data on demand
  1. Registry of Business Objects (EDITABLE!)
  2. Maker - Dynamically calling the Make method on your custom classes to build an object
  3. Factory methods  - Automation of the created data
  4. Test Context. Set from Custom Metadata c_TestSettings__Mtd. Public so they may be overridden in code.
  5. Utility methods 

 @Usage: To create a new object template i) add the business name of the object you are templating to the "Entity" enum. ii) create a new 'maker' Class inheriting from c_TestFactoryMaker and map a reference to the new class from the ENUM in the map 'makers' below.
 
 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       Draft - A generic context and a basic factory automation for object creation
  1.1         Matt Evans       7/12/2018       Inclusion of custom setting c_TestSettings__c
  1.2         Matt Evans       9/9/2019        Introduced reflection to connect sObject son relational fields to ID fields (ex. Contact.Account to Contact.AccountId). Fixed an issue with creating composite objects.
  1.3         Matt Evans       17/9/2019       Protoyping speeding up the type and sObject references for CPU time
*/
public virtual class c_TestFactory {


    /**
    * Registry of Business Objects 
    * - Allows the factory to map and create sObjects and sets of sObjects
    **/

    /**
    * Entity: EDITABLE: Business Object Entities: Each ENUM is a label representing a business object to be built. When you create a new object, decide on a name and add it here:
    **/
    public enum Entity {
        //...The order is IMPORTANT!!! It defines the order of the DML. If you need one object inserted before another, this must be reflected here.
        ADMIN_USER
        ,COUNTRY_USER
        ,SALES_ACCOUNT
        ,SALES_CONTACT
        ,SALES_OPPORTUNITY
        ,CUSTOMER
        //...Add more here as you go...
    }

    /**
    * makers: EDITABLE: Maps your ENUM Business Objects to the actual "maker" Classes that will generate the sObject records and keep an index of them to insert later
    **/
    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {
            /*...Map your Entity labels to their maker class here...*/
            Entity.ADMIN_USER => new c_TestFactory_CoreUsers.StandardSystemAdmin()
            ,Entity.COUNTRY_USER => new c_TestFactory_Users.CountryUser()
            ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
            ,Entity.SALES_CONTACT  => new c_TestFactory_SalesCloud.SalesContact()
            ,Entity.SALES_OPPORTUNITY  => new c_TestFactory_SalesCloud.SalesOpportunity()
            ,Entity.CUSTOMER  => new c_TestFactory_SalesCloud.Customer()
            //...Add more here as you go...*/
    };


    /**
    * ************* DO NOT EDIT BELOW THIS LINE *************
    **/

    /**
    * Maker - Dynamically calling the Make method on your custom classes to build an object
    * - Implemented on every Business Object's maker class as they all inherrit from c_TestFactoryMaker
    *  - Creates and returns one or more sObject records based on default values, merged with any sObject passed
    *  - Every sObject created by the class is kept in a list, so that the factory can check through them to group DML and automate the insert process
    **/
    public static sObject make(Entity businessObjectToCreate) {
        return make(businessObjectToCreate, null);
    }

    public static sObject make(Entity businessObjectToCreate, sObject sourceObject) {
        c_TestFactoryMaker businessObject = makers.get(businessObjectToCreate);
        return businessObject.make(sourceObject);
        // return businessObject.pop(); // replaced by get()[0] to return the FIRST rather than LAST item from the list
        // return businessObject.get()[0]; // Get first incase the object creates a long list of items, like a composite list
    }

    /**
    * Factory methods  - Automation of the created data
    **/

    // Method "RUN"
    //  - Execute the factory context and run the DML. Default behaviour is to flush the list of records after inserting

    public static void run() {
        System.debug(LoggingLevel.INFO,'@@ START: Test Factory run() @@');
        run(FALSE); // run with do not clear flag set to FALSE. Result is list gets flushed and cleared after execution.
        System.debug(LoggingLevel.INFO,'@@ START: Test Factory run() complete @@');
    }

    //  - Run, but without flushing the list, allowing it to be re-used after DML has been completed
    public static void run(Boolean do_not_clear) {
        System.debug(LoggingLevel.INFO,'@@ START: Test Factory run(do_not_clear='+do_not_clear+') @@');

        // Create each set of business objects in order of the Entity ENUM
        for (Entity e : Entity.values()) {
            createEntity(e, !do_not_clear);
        }

        System.debug(LoggingLevel.INFO,'@@ START: Test Factory run(do_not_clear='+do_not_clear+') complete @@');
    }


    // Create Entities
    //  - Get the sObjects from each business object and insert them to the database in order
    //  - For composite objects ensure mixed sObject types are ordered so that parents precede children
    //  - Ex. Pseudo code: [Account 1 followed by the account's Contacts 1,2,3,4; then Account 2 and child Contacts 6,7,8; then Cases; etc.]

    static void createEntity(Entity businessObjectToCreate, Boolean clearObjects) {
        System.debug(LoggingLevel.INFO,'@@ START: Test Factory Create Entity '+ businessObjectToCreate +' @@');

        // Objects to insert when we are ready
        sObject[] objs = new List<sObject>();

        // Get all the sObject records from the Business Object's class, generated every time the 'make' method was run
        if (!makers.containsKey(businessObjectToCreate)) {
            // There's a miss match between entities and makers. Instead of breaking the whole app we will report the bug and break this loop
            System.debug(LoggingLevel.ERROR, '@@ The business object '+businessObjectToCreate+' is not mapped to a factory class in the makers map corrcetly. Make sure it is not missing, is spelled correctly or hasnt been removed.');
            return; 
        }
        // System.debug(LoggingLevel.INFO,'@@ Adding ' + makers.get(businessObjectToCreate).get().size() + ' ' + businessObjectToCreate + ' elements to the list');
        objs.addAll(makers.get(businessObjectToCreate).get());

        // Sort the list of sobject record by Type, in order of discovery (FIFO)
        // - This allows DML to be run on each type of sObject record, and Id's to be populated to enable records to be joined

        List<String> createOrder = new List<String>();
        Map<String, sObject[]> collections_INSERT = new map<String, sObject[]>();
        Map<String, sObject[]> collections_UPDATE = new map<String, sObject[]>();

        // Speed up the list by indexing relationsional field map by sObjects invovled
        // This is very fast, but will we get different SObject types in the class? TODO: Work it out!
        Set<String> sObjectTokens = new Set<String>();
        for (sObject o : objs) {
            String tokenName  = o.getToken();
            if (tokenName!=null) {
                SObjectType r = ((SObject)(Type.forName('Schema.'+tokenName).newInstance())).getSObjectType();
                DescribeSObjectResult d = r.getDescribe();
                setRelationalFieldMap(d);
            }
        }

        for (sObject o : objs) {
            // While looping over each record, we will inspect the relationship fields to dynamically assign ID's from any sObject
            // that the template joined (Ex. assign an AccoutId from an sObject on the Account field on Contact, or a __r reference)
            // This allows us to set sObjects to be assigned to reference fields when building out composite objects
            Map<String,String> relationalFieldMap = getRelationalFieldMap(o.getToken());
            if (relationalFieldMap!=null) {
                for(String fieldName : relationalFieldMap.keySet()) {
                    String relationshipName = relationalFieldMap.get(fieldName);
                    sObject relationshipObj = o.getSObject(relationshipName);
                    if (relationshipObj!=null && relationshipObj.id!=null) {
                        System.debug(LoggingLevel.INFO, '@@ Sobject in Relationship field '+relationshipName+' is assigning ' + fieldName+' with value '+relationshipObj.id);
                        o.put(fieldName,relationshipObj.id);
                    }
                }
            }
            
            // Now sort the records into UPDATE or INSERT DML, storing with object name as key
            String name = o.getSObjectType().getDescribe().getName();
            if (o.get('Id')!=null)
            {
                if (!collections_UPDATE.containsKey(name)) {
                    createOrder.add(name);
                }

                sObject[] objectsByType = collections_UPDATE.containsKey(name) ? collections_UPDATE.get(name) : new List<sObject>();
                objectsByType.add(o);

                collections_UPDATE.put(name, objectsByType);
            } else {
                if (!collections_INSERT.containsKey(name)) {
                    createOrder.add(name);
                }

                sObject[] objectsByType = collections_INSERT.containsKey(name) ? collections_INSERT.get(name) : new List<sObject>();
                objectsByType.add(o);

                collections_INSERT.put(name, objectsByType);
            }

        }

        // Upsert the sobject lists in order, allowing for ID's and external ID's to be created in each transaction
        // - DML should not be in a loop ;) but we are limiting this by TYPE and therefore this should not be called more than the number of sObject types being created

        for (String name : createOrder) {
            
            if (collections_UPDATE.containsKey(name) && collections_UPDATE.get(name).size()>0) update (collections_UPDATE.get(name));
            if (collections_INSERT.containsKey(name) && collections_INSERT.get(name).size()>0) insert (collections_INSERT.get(name));
        }


        // Clear the list of sObject records on the Business Object
        // - this is default behaviour, however use "runAndKeepContext" if you want to keep the sObjects on the business objects in memory
        // - flushing them reduces the amount of working memory, and reduces the amount of repeated DML if run() is called more than once
        // - if the developer wishes to avoid this, call run(true)
        if (clearObjects) makers.get(businessObjectToCreate).clear();

        System.debug(LoggingLevel.INFO,'@@ END: Test Factory Create Entity '+ businessObjectToCreate +' @@');
    }

    /**
    * Test Context. Set from Custom Metadata c_TestSettings__Mtd. Public so they may be overridden in code.
    **/
    public static String COUNTRY_CODE {get{if (COUNTRY_CODE==null) setDefaultContext(); return COUNTRY_CODE;} set{COUNTRY_CODE = value;}}
    public static String COUNTRY_NAME {get{if (COUNTRY_NAME==null) setDefaultContext(); return COUNTRY_NAME;} set{COUNTRY_NAME = value;}}
    public static String TIMEZONE_SID_KEY {get{if (TIMEZONE_SID_KEY==null) setDefaultContext(); return TIMEZONE_SID_KEY;} set{TIMEZONE_SID_KEY = value;}}
    public static String LANGUAGE_LOCALE_KEY {get{if (LANGUAGE_LOCALE_KEY==null) setDefaultContext(); return LANGUAGE_LOCALE_KEY;} set{LANGUAGE_LOCALE_KEY = value;}}
    public static String LOCALE_SID_KEY {get{if (LOCALE_SID_KEY==null) setDefaultContext(); return LOCALE_SID_KEY;} set{LOCALE_SID_KEY = value;}}
    public static String CURRENCY_ISO_CODE {get{if (CURRENCY_ISO_CODE==null) setDefaultContext(); return CURRENCY_ISO_CODE;} set{CURRENCY_ISO_CODE = value;}}
    public static String EMAIL_ENCODING_KEY {get{if (EMAIL_ENCODING_KEY==null) setDefaultContext(); return EMAIL_ENCODING_KEY;} set{EMAIL_ENCODING_KEY = value;}}
    public static Boolean BULKIFY_TESTS {get{if (BULKIFY_TESTS==null) setDefaultContext(); return BULKIFY_TESTS;} set{BULKIFY_TESTS = value;}}
    public static Datetime now = System.now();

    public static void setDefaultContext()
    {
        c_TestSettings__mdt [] activeSettings = [SELECT MasterLabel, 
                               QualifiedApiName, 
                               Created__c,
                               Active__c,
                               BULKIFY_TESTS__c,
                               COUNTRY_CODE__c,
                               COUNTRY_NAME__c,
                               CURRENCY_ISO_CODE__c,
                               EMAIL_ENCODING_KEY__c,
                               LANGUAGE_LOCALE_KEY__c,
                               LOCALE_SID_KEY__c,
                               TIMEZONE_SID_KEY__c
                               FROM c_TestSettings__mdt  
                               where Active__c = TRUE
                               Order By Created__c DESC ];

        if (!activeSettings.IsEmpty())
        {
            c_TestSettings__mdt ts = activeSettings[0];
            BULKIFY_TESTS = ts.BULKIFY_TESTS__c;
            COUNTRY_CODE = ts.COUNTRY_CODE__c;
            COUNTRY_NAME = ts.COUNTRY_NAME__c;
            CURRENCY_ISO_CODE = ts.CURRENCY_ISO_CODE__c;
            EMAIL_ENCODING_KEY = ts.EMAIL_ENCODING_KEY__c;
            LANGUAGE_LOCALE_KEY = ts.LANGUAGE_LOCALE_KEY__c;
            LOCALE_SID_KEY = ts.LOCALE_SID_KEY__c;
            TIMEZONE_SID_KEY = ts.TIMEZONE_SID_KEY__c;
        }
    }


    /**
    * Utility methods 
    * 1. Field merger
    * 2. Map relational fields
    **/

    // Incorporate fields into passed object
    public static sObject mergeFields(sObject source, sObject destination) {
        return mergeFields(source, destination, false);
    }
    static sObject mergeFields(sObject source, sObject destination, boolean overwrite) {
        if (destination==null)
        {
            destination = source;
            return destination;
        }
        Map<String, Object> fieldsToValue = source.getPopulatedFieldsAsMap();
        for (String fieldName : fieldsToValue.keySet()) {
            if (overwrite || !overwrite && destination.get(fieldName) == null) {
                destination.put(FieldName, source.get(FieldName));
            }
        }
        return destination;
    }


    // Map relational fields 
    // Mapping once all fields on an object limits the need to loop large lists of fields repeately per transaction
    static Map<String, Map<String, String>> objectRelationalFieldMap = new Map<String, Map<String, String>>();
    static Map<String, String> setRelationalFieldMap(Schema.DescribeSObjectResult res) {
        String objectName = res.getName();

        // If we've already built the map, return values instead of looping the field set again
        if (!objectRelationalFieldMap.containsKey(objectName)) {
            // Get the field name and the relational field name ex. field with name "AccountId" on Contact has relationalfield name "Account"
            Map<String, String> fieldNameToRelationshipName = new Map<String,String>();
                
            // Field info to cache
            for(Schema.SobjectField f : res.fields.getMap().Values()) {    

                // Only get relation fields (Loopup and master relations)       
                if (f.getDescribe().getReferenceTo().size()>0 && f.getDescribe().getRelationshipName()!=null) {

                    String fieldName = f.getDescribe().getName();
                    String relationshipName = f.getDescribe().getRelationshipName();
                    fieldNameToRelationshipName.put(fieldName, relationshipName);
                }
            }
            // store only necessary fields in the map
            objectRelationalFieldMap.put(objectName, fieldNameToRelationshipName);
        }
        return objectRelationalFieldMap.get(objectName);
    }
    static Map<String, String> getRelationalFieldMap(String objectName) {
        return objectRelationalFieldMap.get(objectName);
    }

    /**
    * Exception Class
    */

    public class TestFactoryException extends Exception {}
//*/
}