/**
 @Name: c_TestFactoryAutomation.cls
 @TestedBy: Implementing in a test class
 @Description: TestFactory Framework automation class; generates test data on demand.
  This class should not need to be edited.
  1. Make methods - 'Make'objects in memory - dynamically calls the Make method on a custom template classes to build an object
  3. Automation methods  - 'Run' automation of the created data
  4. Test Context. Set from Custom Metadata c_TestSettings__Mtd. Public so they may be overridden in code.
  5. Utility methods 

 @Usage: Your test class should inherit from here, and use the methods in the automation class (Make() and Run()) to generate test data (Make) and methods to insert it (Run)

 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       Draft - A generic context and a basic factory automation for object creation
  1.1         Matt Evans       7/12/2018       Inclusion of custom setting c_TestSettings__c
  1.2         Matt Evans       9/9/2019        Introduced reflection to connect sObject son relational fields to ID fields (ex. Contact.Account to Contact.AccountId). Fixed an issue with creating composite objects.
  1.3         Matt Evans       17/9/2019       Protoyping speeding up the type and sObject references for CPU time
  1.3.1       Matt Evans       30/9/2019       Tidy. Confirmed CPU improvements.
  1.4         Matt Evans       1/10/2019       Abstracted the entities mapping into another file to make it easier to handle changes
  1.5         Matt Evans       3/10/2019       New inherritance stack to improve readability
*/
public virtual class c_TestFactoryAutomation {

    /**
    * Make - tells the factory to build an object
    * Calling the Make method in your test class to build an object
    * - Creates and returns one or more sObject records based on default values, merged with any sObject passed
    * - Every sObject created by the class is kept in a list, so that the factory can check through them to group DML and automate the insert process
    **/

    // Method "MAKE" / tell the factory to build an object of a certain type
    public static sObject make(c_TestFactory.Entity businessObjectToCreate) {
        return make(businessObjectToCreate, null);
    }

    // Method "MAKE" with sObject to use with initial values, ex. new Account(Name = "My Test Account Name")
    public static sObject make(c_TestFactory.Entity businessObjectToCreate, sObject sourceObject) {
        c_TestFactoryMaker businessObject = c_TestFactory.makers.get(businessObjectToCreate);
        return businessObject.make(sourceObject);
    }

    // Method "getSObjectList" / returns a total list of ALL sObjects created for an entity template
    public static sObject[] getSObjectList(c_TestFactory.Entity businessObjectToCreate) {
        return c_TestFactory.makers.get(businessObjectToCreate).get();
    }

    // Method "getDefaults" / returns the default values for an object, merging them with the source object. Does not add to the factory list. Used for overloading / using another object's default values.
    public static sObject getDefaults(c_TestFactory.Entity businessObjectToGet) {
        c_TestFactoryMaker businessObject = c_TestFactory.makers.get(businessObjectToGet);
        return businessObject.getDefaults();
    }

    /**
    * Run the factory - automating production of entities
    **/

    // Method "RUN"
    //  - Execute the factory context and run the DML. Default behaviour is to flush the list of records after inserting

    public static void run() {
        run(TRUE); // run with Clear flag set to TRUE. Result is list gets flushed and cleared after execution.
    }

    // Method "RUN" with overload - Run, and allow option to not flush the list, allowing it to be re-used after DML has been completed.
    public static void run(Boolean clearObjects) {
        // Create each set of business objects in order of the c_TestFactory.Entity ENUM
        for (c_TestFactory.Entity businessObjectToCreate : c_TestFactory.Entity.values()) {
            System.Debug(LoggingLevel.INFO,'@@ Create c_TestFactory.Entity '+businessObjectToCreate+ ' size '+c_TestFactory.makers.get(businessObjectToCreate).get().size());
            if (c_TestFactory.makers.get(businessObjectToCreate).get().size()>0) {
                createEntity(businessObjectToCreate, clearObjects);
            }
        }
    }

    // Create Entities
    //  - Get the sObjects from each business object and insert them to the database in order
    //  - For composite objects ensure mixed sObject types are ordered so that parents precede children
    //  - Ex. Pseudo code: [Account 1 followed by the account's Contacts 1,2,3,4; then Account 2 and child Contacts 6,7,8; then Cases; etc.]

    static void createEntity(c_TestFactory.Entity businessObjectToCreate, Boolean clearObjects) {
        //System.debug(LoggingLevel.INFO,'@@ START: Test Factory Create c_TestFactory.Entity '+ businessObjectToCreate +' : clear objects:'+clearObjects+'@@');
        //System.debug(LoggingLevel.INFO,'@@ CPU time '+System.Limits.getCpuTime());

        // Objects to insert when we are ready
        sObject[] objs = new List<sObject>();

        // Get all the sObject records from the Business Object's class, generated every time the 'make' method was run
        if (!c_TestFactory.makers.containsKey(businessObjectToCreate)) {
            // There's a miss match between entities and c_TestFactory.makers. Instead of breaking the whole app we will report the bug and break this loop
            System.debug(LoggingLevel.ERROR, '@@ The business object '+businessObjectToCreate+' is not mapped to a factory class in the makers map corrcetly. Make sure it is not missing, is spelled correctly or hasnt been removed.');
            return; 
        }
        // System.debug(LoggingLevel.INFO,'@@ Adding ' + c_TestFactory.makers.get(businessObjectToCreate).get().size() + ' ' + businessObjectToCreate + ' elements to the list');
        objs.addAll(c_TestFactory.makers.get(businessObjectToCreate).get());

        // Sort the list of sobject record by Type, in order of discovery (FIFO)
        // - This allows DML to be run on each type of sObject record, and Id's to be populated to enable records to be joined

        List<String> createOrder = new List<String>();
        Map<String, sObject[]> collections_INSERT = new map<String, sObject[]>();
        Map<String, sObject[]> collections_UPDATE = new map<String, sObject[]>();

        // Speed up the list by indexing relationsional field map by sObjects invovled
        // This is very fast, but will we get different SObject types in the class? TODO: Work it out!
        Set<String> sObjectTokens = new Set<String>();
        for (sObject o : objs) {
            setRelationalFieldMap(o);
        }

        for (sObject o : objs) {
            // While looping over each record, we will inspect the relationship fields to dynamically assign ID's from any sObject
            // that the template joined (Ex. assign an AccoutId from an sObject on the Account field on Contact, or a __r reference)
            // This allows us to set sObjects to be assigned to reference fields when building out composite objects
            String objectName = String.valueOf(o.getSObjectType());
            Map<String,String> relationalFieldMap = getRelationalFieldMap(objectName);
            if (relationalFieldMap!=null) {
                for(String fieldName : relationalFieldMap.keySet()) {
                    String relationshipName = relationalFieldMap.get(fieldName);
                    sObject relationshipObj = o.getSObject(relationshipName);
                    if (relationshipObj!=null && relationshipObj.id!=null) {
                        // System.debug(LoggingLevel.INFO, '@@ Sobject in Relationship field '+relationshipName+' is assigning ' + fieldName+' with value '+relationshipObj.id);
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
        if (clearObjects) c_TestFactory.makers.get(businessObjectToCreate).clear();

        //System.debug(LoggingLevel.INFO,'@@ END: Test Factory Create c_TestFactory.Entity '+ businessObjectToCreate +' @@');
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
    static Map<String, String> setRelationalFieldMap(sObject o) {
        String objectName = String.valueOf(o.getSObjectType());

        // If we've already built the map, return values instead of looping the field set again
        if (!objectRelationalFieldMap.containsKey(objectName)) {
            // Get the field name and the relational field name ex. field with name "AccountId" on Contact has relationalfield name "Account"
            Map<String, String> fieldNameToRelationshipName = new Map<String,String>();
            DescribeSObjectResult res = o.getSObjectType().getDescribe();
                
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