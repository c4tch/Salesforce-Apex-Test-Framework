/**
* File Name   : c_TestFactory
* Description : TestFactory Framework, generates test data on demand
* Modification Log
* ============================================================================
* Ver   Date        Author                  Modification
*-----------------------------------------------------------------------------
* 0.1   7-12-2018   Matt Evans              Draft - A generic context and a basic factory automation for object creation
*
* Instructions
* ============================================================================
* To create a new object,
* i) add the business name to the "Entity" enum
* ii) create a new 'maker' Class inheriting from c_TestFactoryMaker
* iii) and add a reference to the new class to the map 'makers' below.
*
* Examples:
* See c_TestFactory_Sales for an illustraion of how to create an object definition for Sales Cloud
* and c_TestFactory_ExampleUnitTest to see how to use it
* 
*/

public virtual class c_TestFactory {

    /******* Context ******/
    // TODO: Set these default based on the org standard settings
    public static String countryCode = 'SE';
    public static String countryName = 'Sweden';
    public static String timeZoneSidKey = 'Europe/Helsinki';
    public static String LanguageLocaleKey = 'en_US';
    public static String LocaleSidKey = 'en_US';
    public static String currencyIsoCode = 'EUR';
    public static String EmailEncodingKey = 'UTF-8';
    public static Datetime now = System.now();


    /******* Registry of Business Objects ******/
    // Allows dynamic creation of sObject and sets of sObjects for testing

    // Business Object Entities:
    // - Each ENUM is a label representing a business object to be built

    public enum Entity {
        //...The order is important, as it defines the order of the DML
        ADMIN_USER
        ,SALES_USER
        ,SALES_ACCOUNT
        ,SALES_CONTACT
        ,CUSTOMER
        //...Add more here as you go...
    }

    // Map Business Objects to "maker" Classes that generate the data
    // - Each Business Object (Enum) is mapped to a class that will generate the sObject records and keep an index of them to insert later

    public static final Map<Entity, c_TestFactoryMaker> makers = new Map<Entity, c_TestFactoryMaker> {

            //...Map your Entity labels to their maker class here...
            Entity.ADMIN_USER => new c_TestFactory_Users.AdminUser()
            ,Entity.SALES_ACCOUNT => new c_TestFactory_SalesCloud.SalesAccount()
            ,Entity.SALES_CONTACT  => new c_TestFactory_SalesCloud.SalesContact()
            ,Entity.CUSTOMER  => new c_TestFactory_SalesCloud.Customer()
            //...Add more here as you go...

    };

    /******* Calling the Maker Classes from the factory ******/
    // Method "MAKE"
    //  - Implemented on every Business Object's maker class as they all inherrit from c_TestFactoryMaker
    //  - Creates and returns one or more sObject records based on default values, merged with any sObject passed
    //  - Every sObject created by the class is kept in a list, so that the factory can check through them to group DML and automate the insert process

    public static sObject make(Entity businessObjectToCreate) {
        c_TestFactoryMaker businessObject = makers.get(businessObjectToCreate);
        businessObject.make(null);
        return businessObject.pop();
    }

    public static sObject make(Entity businessObjectToCreate, sObject sourceObject) {
        c_TestFactoryMaker businessObject = makers.get(businessObjectToCreate);
        businessObject.make(sourceObject);
        return businessObject.pop();
    }


    /******* Factory methods *******/
    // - Automation of the created data

    // Method "RUN"
    //  - Execute the factory context and run the DML. Default behaviour is to flush the list of records after inserting

    public static void run() {
        System.debug(LoggingLevel.INFO,'@@ START: Test Factory run() @@');

        // Create each set of business objects in order of the Entity ENUM
        for (Entity e : Entity.values()) {
            createEntity(e, TRUE);
        }

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
        objs.addAll(makers.get(businessObjectToCreate).get());

        // Sort the list of sobject record by Type, in order of discovery (FIFO)
        // - This allows DML to be run on each type of sObject record, and Id's to be populated to enable records to be joined

        List<String> createOrder = new List<String>();
        Map<String, sObject[]> collections_INSERT = new map<String, sObject[]>();
        Map<String, sObject[]> collections_UPDATE = new map<String, sObject[]>();

        for (sObject o : objs) {

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


    /******* Utility methods *******/

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

    public class TestFactoryException extends Exception {}

}