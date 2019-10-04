/**
 @Name: c_TestFactoryEntity.cls
 @TestedBy: Implementing in a test class
 @Description: Registry of Business Objects 
 - Update here when creating a new object for use in tests to allow the factory to map and create sObjects and sets of sObjects

 @Usage: 
 1) Your test class should inherit from here to access context, constants and the factory methods "Make" and "Run"
 2) To create a new object template i) add the business name of the object you are templating to the "Entity" enum. ii) create a new 'maker' Class inheriting from c_TestFactoryMaker and map a reference to the new class from the ENUM in the map 'makers' below.
 
 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       Abstracted from the Factory class to make it easier to handle changes
  1.1         Matt Evans       2/10/2019       Composition improved to make Entity directly accessible when inherriting from TestFactoryMaker
  1.2         Matt Evans       9/9/2019        Introduced reflection to connect sObject son relational fields to ID fields (ex. Contact.Account to Contact.AccountId). Fixed an issue with creating composite objects.   
  1.3         Matt Evans       3/10/2019       Refactored to simplify the footprint of the data
*/

public virtual class c_TestFactory extends c_TestFactoryAutomation {
    /********** EDITABLE ENUM ********** 
    * "Entity"
    * When you create a new object, decide on a name and add it here, 
    * then add a refenrece to the method that will act as the template to the map below.
    **/
    public enum Entity {
        //...The order is IMPORTANT!!! It defines the order of the DML. 
        //   If you need one object inserted before another, this _must_ be reflected here.
        ADMIN_USER
        ,COUNTRY_USER
        ,SALES_ACCOUNT
        ,SALES_CONTACT
        ,SALES_OPPORTUNITY
        ,CUSTOMER
        //...Add more here as you go...
    }

    /********** EDITABLE MAP ********** 
    * "makers"
    * Maps entities to the methods that will make the sobject records required.
    * "maker" Classes inherrit an interface from c_TestFactoryMaker so that they can all be "run" 
    * from the main c_TestFactory class
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
    * Bulkify Test switch
    * Reference this in your tests to decide if you should generate a large amount of data, or not
    * Set from Custom Metadata c_TestSettings__Mtd. 
    */
    public static Boolean BULKIFY_TESTS {get{if (BULKIFY_TESTS==null) setDefaultContext(); return BULKIFY_TESTS;} set{BULKIFY_TESTS = value;}}

    /**
    * Test Data Context 
    * Set from Custom Metadata c_TestSettings__Mtd. 
    * Public so they may be overridden in code. 
    * Provieds common context for the objects, such as Country, and a switch Bulkify Tests to define how much data to produce.
    **/
    public static String COUNTRY_CODE {get{if (COUNTRY_CODE==null) setDefaultContext(); return COUNTRY_CODE;} set{COUNTRY_CODE = value;}}
    public static String COUNTRY_NAME {get{if (COUNTRY_NAME==null) setDefaultContext(); return COUNTRY_NAME;} set{COUNTRY_NAME = value;}}
    public static String TIMEZONE_SID_KEY {get{if (TIMEZONE_SID_KEY==null) setDefaultContext(); return TIMEZONE_SID_KEY;} set{TIMEZONE_SID_KEY = value;}}
    public static String LANGUAGE_LOCALE_KEY {get{if (LANGUAGE_LOCALE_KEY==null) setDefaultContext(); return LANGUAGE_LOCALE_KEY;} set{LANGUAGE_LOCALE_KEY = value;}}
    public static String LOCALE_SID_KEY {get{if (LOCALE_SID_KEY==null) setDefaultContext(); return LOCALE_SID_KEY;} set{LOCALE_SID_KEY = value;}}
    public static String CURRENCY_ISO_CODE {get{if (CURRENCY_ISO_CODE==null) setDefaultContext(); return CURRENCY_ISO_CODE;} set{CURRENCY_ISO_CODE = value;}}
    public static String EMAIL_ENCODING_KEY {get{if (EMAIL_ENCODING_KEY==null) setDefaultContext(); return EMAIL_ENCODING_KEY;} set{EMAIL_ENCODING_KEY = value;}}
    public static Datetime NOW = System.now();

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
}