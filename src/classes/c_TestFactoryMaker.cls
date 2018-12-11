/**
* File Name   : c_TestFactoryMaker
* Description : TestFactory Framework, Implements key methods to be extended by data templates
* Modification Log
* ============================================================================
* Ver   Date        Author                  Modification
*-----------------------------------------------------------------------------
* 0.1   7-12-2018   Matt Evans              Draft
*
* Extend from this class to build your own Maker class.
* Each maker class must return a default sObject as a minimum.
*
* For simple business objects, you only need to define the default() method, returning an sObject with default values.
* The standard make method will merge the passed object with the default values automatically and pass that back.
*
* For more complex business objects, where there may be child/parent records or more complex logic the make() method may be overridden completely.
*
*/

public abstract class c_TestFactoryMaker extends c_TestFactory {

    /******* Maker methods *******/

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


    /******* Store each sObject created *******/

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
        data = new List<sObject>();
    }


    /******* Utility methods *******/

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

    /******* Exception Class *******/

    public class TestFactoryBaseException extends Exception {
    }

}