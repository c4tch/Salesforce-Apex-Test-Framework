/**
 @Name: c_TestFactoryMaker.cls
 @OtherClasses: c_TestFactory.cls
 @TestedBy: Implementing in a test class
 @Description:
  TestFactory Framework Maker class, which provides the signature and key methods for your object templates.
  This class shouln't need to be changed, it's job is to provide the base methods for your own template so the facory can treat all objects the same way.
  
 @Usage: To create your own business objects for tests, create a parent Apex class to contain all the objects you will template. Each object in will have it's own sub class, which should extend from c_TestFactoryMaker - this makes sure the Testfactory can work with your new object in a predicatable way. 

  For simple business objects, you only need to define the default() method, returning an sObject with default values.
  The standard make method will merge the passed object with the default values automatically and pass that back.
  
  For more complex business objects, where there may be child/parent records or more complex logic, override the make() method. this will allow you to call other templates, and create relations etc. Always pass back and sObject and follow the signature so the Test factory sees no difference between your custom maker and the standard defined here.
 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       Initial pattern
  1.1         Matt Evans       10/9/2019       Optimised maker with minor tweaks for return values
  1.2         Matt Evans       17/9/2019       Removed descibe calls in loops to and sObject references to improve CPU time
  1.2.1       Matt Evans       30/9/2019       Tidy & included profileIdByNamefile and roleIdByName calls in here as they are so commonly needed
*/

public abstract class c_TestFactoryMaker extends c_TestFactory {

    /**
    * Maker methods
    **/

    // Optional override "make" method
    public virtual sObject make(sObject sourceObject) {

        // Process the custom create method
        sObject rec = (sObject) defaults();

        // Merge default values into passed object
        // - Fields set on the inbound sourceObject record will be preserved
        sourceObject = mergeFields(rec, sourceObject);

        // Add to the Templates's list of records created and return the result for this record
        add(sourceObject);

        return sourceObject;
    }

    // Mandatory implementation "default" method
    abstract sObject defaults();

    /**
    * Access default value method without committing to the list
    **/
    public sObject getDefaults() {
        return (sObject) defaults();
    }

    /**
    * Store each sObject created 
    **/

    sObject[] data = new List<sObject>();

    // Getters and setters to access and manage the stored sObjects

    public void add(sObject objectToAdd) {
        data.add(objectToAdd);
    }
    public sObject[] get() {
        return data;
    }
    public sObject pop() {
        return data.size() > 0 ? data[data.size() - 1] : null;
    }
    public void clear() {
        System.debug(LoggingLevel.INFO, '@@ Clear data');
        this.data = new List<sObject>();
    }


    /**
    * Utility methods 
    **/
    // Incorporate fields into passed object
    public static sObject mergeFields(sObject source, sObject destination) {
        return mergeFields(source, destination, false);
    }

    static sObject mergeFields(sObject source, sObject destination, boolean overwrite) {
        if (destination == null) {
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
    
    // Get Profile -  common for user creation. Use sparringly due to DML; results are cached for the transaction.
    public static String profileIdByName(String profileName) {
        if(!profilesByName.containsKey(profileName)) {
            for(Profile p : [SELECT Id, Name FROM Profile limit 999]) {
                profilesByName.put(p.Name, p.Id);
            }
        }
        return profilesByName.get(profileName);
    }
    static map<String, Id> profilesByName = new Map<String, Id>();

    // Get Role -  common for user creation. Use sparringly due to DML; results are cached for the transaction.
    public static String roleIdByName(String developerName) {
        if(!rolesByName.containsKey(developerName)) {
            UserRole[] r = [select Id from UserRole where DeveloperName = :developerName];
            if (r!=null && !r.IsEmpty())
                rolesByName.put(developerName,r[0].Id);
        }
        return rolesByName.get(developerName);
    }
    static map<String, Id> rolesByName = new Map<String, Id>();


    /**
    * Exception Class 
    **/
    public class TestFactoryBaseException extends Exception {
    }
    
//*/
}